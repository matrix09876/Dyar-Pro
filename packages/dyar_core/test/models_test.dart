import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dyar_core/dyar_core.dart';
import 'fake_doc.dart';

void main() {
  group('Store.fromDoc', () {
    test('يحلّل الحقول الأساسية والإحداثيات', () {
      final s = Store.fromDoc(FakeDoc('s1', {
        'ownerUid': 'p1', 'name': 'مطعم الجليل', 'type': 'restaurant',
        'isOpen': true, 'status': 'approved', 'rating': 4.5, 'ratingCount': 20,
        'deliveryFee': 1500, 'minOrder': 4000, 'prepTimeMins': 18,
        'location': {'lat': 32.86, 'lng': 35.37},
      }));
      expect(s.id, 's1');
      expect(s.name, 'مطعم الجليل');
      expect(s.isOpen, isTrue);
      expect(s.rating, 4.5);
      expect(s.lat, closeTo(32.86, 0.001));
      expect(s.lng, closeTo(35.37, 0.001));
    });

    test('وسوم الحِمية + الحلال/الكوشير + التوثيق', () {
      final s = Store.fromDoc(FakeDoc('s2', {
        'name': 'x', 'type': 'grocery',
        'dietary': ['halal', 'vegetarian'], 'dietaryVerified': true,
        'sabbathAware': true,
      }));
      expect(s.isHalal, isTrue);
      expect(s.isKosher, isFalse);
      expect(s.dietary, contains('vegetarian'));
      expect(s.dietaryVerified, isTrue);
      expect(s.sabbathAware, isTrue);
    });

    test('قيم افتراضية آمنة عند نقص الحقول', () {
      final s = Store.fromDoc(FakeDoc('s3', {}));
      expect(s.status, 'pending');
      expect(s.dietary, isEmpty);
      expect(s.dietaryVerified, isFalse);
      expect(s.lat, isNull);
    });
  });

  group('MenuItem.fromDoc', () {
    test('minQty افتراضي 1 ووسوم الحِمية', () {
      final m = MenuItem.fromDoc(FakeDoc('i1', {
        'name': 'فلافل', 'price': 1200, 'dietary': ['vegan']}));
      expect(m.minQty, 1);
      expect(m.available, isTrue);
      expect(m.dietary, ['vegan']);
    });
    test('minQty للجملة', () {
      final m = MenuItem.fromDoc(FakeDoc('i2', {
        'name': 'صندوق', 'price': 9000, 'minQty': 12}));
      expect(m.minQty, 12);
    });
  });

  group('AppUser.fromDoc', () {
    test('الدور + التاجر B2B + النقاط + الحظر', () {
      final u = AppUser.fromDoc(FakeDoc('u1', {
        'role': 'partner', 'name': 'أمين', 'walletBalance': 5000,
        'merchant': true, 'points': 240, 'status': 'blocked',
        'allergies': ['سمسم'],
      }));
      expect(u.role, UserRole.partner);
      expect(u.merchant, isTrue);
      expect(u.points, 240);
      expect(u.blocked, isTrue);
      expect(u.allergies, contains('سمسم'));
    });
    test('افتراضي customer غير محظور', () {
      final u = AppUser.fromDoc(FakeDoc('u2', {}));
      expect(u.role, UserRole.customer);
      expect(u.merchant, isFalse);
      expect(u.points, 0);
      expect(u.blocked, isFalse);
    });
  });

  group('FeatureFlags', () {
    test('on(): الافتراضي ظاهر، والإطفاء العالمي، وتجاوز المنطقة', () {
      const f = FeatureFlags(
        {'taxi': false, 'marketplace': true},
        {'nazareth': {'taxi': true}},
      );
      expect(f.on('jobs'), isTrue); // غير مذكور → افتراضي ظاهر
      expect(f.on('taxi'), isFalse); // مُطفأ عالميًا
      expect(f.on('taxi', region: 'nazareth'), isTrue); // المنطقة تتجاوز
      expect(f.on('marketplace'), isTrue);
    });
    test('fromDoc يحلّل العالمي وbyRegion', () {
      final f = FeatureFlags.fromDoc(FakeDoc('features', {
        'loyalty': false,
        'byRegion': {'akko': {'loyalty': true}},
      }));
      expect(f.on('loyalty'), isFalse);
      expect(f.on('loyalty', region: 'akko'), isTrue);
    });
  });

  group('DyarStory.fromDoc', () {
    test('عناصر متعددة (صورة+فيديو) + الغلاف', () {
      final st = DyarStory.fromDoc(FakeDoc('st1', {
        'title': 'عرض', 'active': true,
        'items': [
          {'type': 'video', 'url': 'v.mp4'},
          {'type': 'image', 'url': 'a.jpg', 'durationSec': 7},
        ],
      }));
      expect(st.items.length, 2);
      expect(st.items[0].isVideo, isTrue);
      expect(st.items[1].durationSec, 7);
      expect(st.cover, 'a.jpg'); // أول صورة
    });
    test('توافق الصيغة المفردة image', () {
      final st = DyarStory.fromDoc(FakeDoc('st2', {
        'title': 'x', 'image': 'single.jpg'}));
      expect(st.items.length, 1);
      expect(st.items.first.type, 'image');
      expect(st.cover, 'single.jpg');
    });
    test('StoryItem.fromMap: مدة الفيديو والصورة', () {
      final v = StoryItem.fromMap({'type': 'video', 'url': 'v.mp4'});
      expect(v.isVideo, isTrue);
      final img = StoryItem.fromMap({'type': 'image', 'url': 'a.jpg', 'durationSec': 9});
      expect(img.durationSec, 9);
      expect(img.isVideo, isFalse);
    });
  });

  group('MealAccount.fromDoc (ديار Meals)', () {
    test('رصيد + دورة + hasBudget', () {
      final a = MealAccount.fromDoc(FakeDoc('alice', {
        'orgId': 'org1', 'balance': 2500, 'period': 'daily'}));
      expect(a.orgId, 'org1');
      expect(a.balance, 2500);
      expect(a.hasBudget, isTrue);
    });
    test('رصيد صفر = لا ميزانية', () {
      final a = MealAccount.fromDoc(FakeDoc('x', {'balance': 0}));
      expect(a.hasBudget, isFalse);
      expect(a.period, 'daily');
    });
  });

  group('DriverProfile.fromDoc', () {
    test('الأرباح المتداخلة + الحالة + أونلاين', () {
      final d = DriverProfile.fromDoc(FakeDoc('d1', {
        'vehicle': {'type': 'motorcycle', 'plate': '12-345-67'},
        'isOnline': true, 'status': 'approved',
        'earnings': {'today': 3200, 'week': 18000, 'total': 240000},
        'rating': 4.8,
      }));
      expect(d.vehicleType, 'motorcycle');
      expect(d.isOnline, isTrue);
      expect(d.earningsToday, 3200);
      expect(d.earningsTotal, 240000);
      expect(d.rating, 4.8);
    });
    test('قيم افتراضية آمنة', () {
      final d = DriverProfile.fromDoc(FakeDoc('d2', {}));
      expect(d.status, 'pending');
      expect(d.earningsTotal, 0);
      expect(d.isOnline, isFalse);
    });
  });

  group('Rfq.fromDoc (ديار B2B)', () {
    test('طلب مفتوح بلا عرض', () {
      final r = Rfq.fromDoc(FakeDoc('rfq1', {
        'merchantUid': 'alice', 'storeId': 's1', 'storeName': 'مورد',
        'productName': 'دقيق', 'qty': 100, 'status': 'open',
      }));
      expect(r.isOpen, isTrue);
      expect(r.isQuoted, isFalse);
      expect(r.qty, 100);
      expect(r.quote, isNull);
    });
    test('عرض مع عمولة + صلاحية مستقبلية', () {
      final future = Timestamp.fromDate(
          DateTime.now().add(const Duration(hours: 6)));
      final r = Rfq.fromDoc(FakeDoc('rfq2', {
        'merchantUid': 'alice', 'storeId': 's1', 'productName': 'سكر',
        'qty': 50, 'status': 'quoted',
        'quote': {
          'unitPrice': 500, 'total': 25000, 'commission': 750,
          'commissionPct': 3, 'validUntil': future,
        },
      }));
      expect(r.isQuoted, isTrue);
      expect(r.quote!.unitPrice, 500);
      expect(r.quote!.total, 25000);
      expect(r.quote!.commission, 750);
      expect(r.quote!.commissionPct, 3);
      expect(r.quote!.isValid, isTrue);
    });
    test('عرض منتهي الصلاحية → isValid=false', () {
      final past = Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 1)));
      final q = RfqQuote.fromMap({
        'unitPrice': 100, 'total': 1000, 'commission': 30,
        'commissionPct': 3, 'validUntil': past,
      });
      expect(q.isValid, isFalse);
    });
  });

  group('AiCartSuggestion.fromMap (ديار AI)', () {
    test('اقتراح كامل بأصناف وإجمالي', () {
      final sug = AiCartSuggestion.fromMap({
        'usedAi': true, 'overBudget': false,
        'storeId': 's1', 'storeName': 'مطعم', 'storeType': 'restaurant',
        'explanation': 'اخترنا الأوفر', 'deliveryFee': 1500,
        'subtotal': 6000, 'estimatedTotal': 7500,
        'items': [
          {'itemId': 'i1', 'name': 'شاورما', 'price': 3000, 'qty': 2, 'lineTotal': 6000},
        ],
      });
      expect(sug.usedAi, isTrue);
      expect(sug.items.length, 1);
      expect(sug.items.first.lineTotal, 6000);
      expect(sug.estimatedTotal, 7500);
      expect(sug.overBudget, isFalse);
    });
    test('قيم افتراضية آمنة عند نقص الحقول', () {
      final sug = AiCartSuggestion.fromMap({'storeId': 's2'});
      expect(sug.items, isEmpty);
      expect(sug.subtotal, 0);
      expect(sug.usedAi, isFalse);
    });
  });
}
