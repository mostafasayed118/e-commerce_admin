import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/core/entities/coupon.dart';
import 'package:shop_admin/core/error/app_error.dart';
import 'package:shop_admin/core/error/result.dart';
import 'package:shop_admin/data/database/app_database.dart';
import 'package:shop_admin/data/database/daos/coupon_dao.dart';
import 'package:shop_admin/data/database/mappers/coupon_mapper.dart';
import 'package:shop_admin/data/repositories/coupon_repository_impl.dart';
import 'package:shop_admin/domain/repositories/coupon_repository.dart';

void main() {
  late AppDatabase db;
  late CouponRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = CouponRepositoryImpl(CouponDao(db), CouponMapper());
  });

  tearDown(() => db.close());

  Coupon draft({
    String code = 'SAVE10',
    CouponDiscountType type = CouponDiscountType.percent,
    int value = 10,
  }) =>
      Coupon(id: 0, code: code, type: type, value: value);

  test('createCoupon normalizes the code (uppercase, trimmed)', () async {
    final result = await repo.createCoupon(draft(code: '  save10 '));

    final coupon = result.getOrThrow();
    expect(coupon.code, 'SAVE10');
    expect(coupon.id, greaterThan(0));
    expect(coupon.isActive, isTrue, reason: 'active is the default');
    expect(coupon.usedCount, 0);
    expect(coupon.minSpendCents, 0);
  });

  test('createCoupon rejects a duplicate code (any casing)', () async {
    await repo.createCoupon(draft());

    final dup = await repo.createCoupon(draft(code: 'save10'));
    expect(dup, isA<Failure<Coupon>>());
    final error = (dup as Failure<Coupon>).error;
    expect(error, isA<ValidationError>());
    expect(error.code, AppErrorCode.couponCodeTaken);
  });

  test('getByCode normalizes the lookup and returns null when missing',
      () async {
    await repo.createCoupon(draft());

    final found = await repo.getByCode('  SAVE10 ');
    expect(found.getOrThrow()?.code, 'SAVE10');

    final missing = await repo.getByCode('NOPE');
    expect(missing.getOrThrow(), isNull);
  });

  test('optional fields round-trip (expiry, usage cap, min spend)', () async {
    final created = (await repo.createCoupon(Coupon(
      id: 0,
      code: 'FLASH',
      type: CouponDiscountType.fixed,
      value: 2500,
      minSpendCents: 5000,
      expiresAt: DateTime(2026, 12, 31),
      maxUses: 3,
      isActive: false,
    ))).getOrThrow();
    expect(created.minSpendCents, 5000);
    expect(created.expiresAt, DateTime(2026, 12, 31));
    expect(created.maxUses, 3);
    expect(created.isActive, isFalse);

    final reloaded = (await repo.getByCode('FLASH')).getOrThrow()!;
    expect(reloaded.type, CouponDiscountType.fixed);
    expect(reloaded.value, 2500);
    expect(reloaded.expiresAt, DateTime(2026, 12, 31));
    expect(reloaded.maxUses, 3);
  });

  test('updateCoupon edits fields and excludes itself from the duplicate check',
      () async {
    final a = (await repo.createCoupon(draft(code: 'A'))).getOrThrow();
    final b = (await repo.createCoupon(draft(code: 'B', value: 20)))
        .getOrThrow();

    // A keeps its own code — allowed even though it already exists.
    final updated = (await repo.updateCoupon(a.copyWith(value: 15)))
        .getOrThrow();
    expect(updated.value, 15);
    expect(updated.code, 'A');

    // B tries to take A's code — rejected.
    final clash = await repo.updateCoupon(b.copyWith(code: 'A'));
    expect(clash, isA<Failure<Coupon>>());
    expect((clash as Failure<Coupon>).error.code, AppErrorCode.couponCodeTaken);
  });

  test('deleteCoupon removes the row', () async {
    final created = (await repo.createCoupon(draft())).getOrThrow();

    expect((await repo.deleteCoupon(created.id)).isSuccess, isTrue);
    expect((await repo.getByCode('SAVE10')).getOrThrow(), isNull);
  });

  test('watchCoupons emits the list and re-emits on change', () async {
    final done = expectLater(
      repo.watchCoupons(),
      emitsInOrder([
        isEmpty,
        isA<List<Coupon>>().having((c) => c.single.code, 'code', 'SAVE10'),
      ]),
    );

    await pumpEventQueue();
    await repo.createCoupon(draft());

    await done;
  });
}
