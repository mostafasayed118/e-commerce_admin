import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:shop_admin/core/entities/coupon.dart';
import 'package:shop_admin/core/error/result.dart';
import 'package:shop_admin/domain/repositories/coupon_repository.dart';
import 'package:shop_admin/presentation/features/admin/coupons/admin_coupons_cubit.dart';

class MockCouponRepository extends Mock implements CouponRepository {}

void main() {
  late MockCouponRepository repo;

  final coupon = Coupon(
    id: 1,
    code: 'SAVE10',
    type: CouponDiscountType.percent,
    value: 10,
  );

  setUpAll(() {
    // mocktail: any() on the non-nullable Coupon arg needs a fallback value.
    registerFallbackValue(const Coupon(
      id: 0,
      code: 'X',
      type: CouponDiscountType.percent,
      value: 1,
    ));
  });

  setUp(() {
    repo = MockCouponRepository();
  });

  test('starts loading then emits the watched list', () async {
    when(() => repo.watchCoupons()).thenAnswer((_) => Stream.value([coupon]));
    final cubit = AdminCouponsCubit(repo);
    addTearDown(cubit.close);

    expect(cubit.state, isA<AdminCouponsLoading>());
    await pumpEventQueue();

    expect(cubit.state, isA<AdminCouponsLoaded>());
    expect((cubit.state as AdminCouponsLoaded).coupons, [coupon]);
  });

  test('a watch-stream error surfaces AdminCouponsError', () async {
    when(() => repo.watchCoupons()).thenAnswer((_) => Stream.error('boom'));
    final cubit = AdminCouponsCubit(repo);
    addTearDown(cubit.close);

    await pumpEventQueue();

    expect(cubit.state, isA<AdminCouponsError>());
  });

  test('createCoupon delegates to the repository and returns its Result',
      () async {
    when(() => repo.watchCoupons()).thenAnswer((_) => Stream.value([]));
    when(() => repo.createCoupon(any()))
        .thenAnswer((_) async => Success(coupon));
    final cubit = AdminCouponsCubit(repo);
    addTearDown(cubit.close);

    final result = await cubit.createCoupon(coupon);

    expect(result, isA<Success<Coupon>>());
    expect(result.getOrThrow(), coupon);
    verify(() => repo.createCoupon(coupon)).called(1);
  });

  test('updateCoupon delegates to the repository', () async {
    when(() => repo.watchCoupons()).thenAnswer((_) => Stream.value([]));
    when(() => repo.updateCoupon(any()))
        .thenAnswer((_) async => Success(coupon.copyWith(value: 15)));
    final cubit = AdminCouponsCubit(repo);
    addTearDown(cubit.close);

    final result = await cubit.updateCoupon(coupon.copyWith(value: 15));

    expect(result, isA<Success<Coupon>>());
    expect(result.getOrThrow().value, 15);
    verify(() => repo.updateCoupon(coupon.copyWith(value: 15))).called(1);
  });

  test('deleteCoupon delegates to the repository', () async {
    when(() => repo.watchCoupons()).thenAnswer((_) => Stream.value([]));
    when(() => repo.deleteCoupon(1))
        .thenAnswer((_) async => const Success<void>(null));
    final cubit = AdminCouponsCubit(repo);
    addTearDown(cubit.close);

    final result = await cubit.deleteCoupon(1);

    expect(result.isSuccess, isTrue);
    verify(() => repo.deleteCoupon(1)).called(1);
  });
}
