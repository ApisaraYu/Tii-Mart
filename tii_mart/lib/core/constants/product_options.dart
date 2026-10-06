/// หมวดหมู่สินค้า (ภายหลังจะย้ายไปเก็บใน Firestore collection categories ได้)
const productCategories = <String>[
  'โน้ตบุ๊ก',
  'จอมอนิเตอร์',
  'คีย์บอร์ดและเมาส์',
  'หูฟังและลำโพง',
  'สาย พอร์ต และฮับ',
  'อุปกรณ์เก็บข้อมูล',
  'อื่นๆ',
];

/// ระบบปฏิบัติการที่รองรับ (ใช้ตอบ pain-point "ใช้กับ Windows/Mac ได้ไหม")
const osOptions = <String>['Windows', 'macOS', 'Linux', 'ไม่ระบุ'];
