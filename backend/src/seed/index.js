import 'dotenv/config';
import mongoose from 'mongoose';
import { connectDB } from '../config/db.js';
import User from '../models/User.js';
import Profile from '../models/Profile.js';
import Company from '../models/Company.js';
import JobOffer from '../models/JobOffer.js';
import Banner from '../models/Banner.js';
import Application from '../models/Application.js';
import Conversation from '../models/Conversation.js';
import Message from '../models/Message.js';
import Notification from '../models/Notification.js';
import Report from '../models/Report.js';
import SavedItem from '../models/SavedItem.js';
import { OFFER_STATUS, ROLES } from '../config/constants.js';

// بيانات أوّلية للتجريب — تعكس الشاشات الواردة في نموذج التصميم
const COMPANIES = [
  {
    name: 'شركة البناء الجزائرية',
    sector: 'construction',
    wilaya: 'الجزائر العاصمة',
    description: 'مؤسسة رائدة في مجال البناء والأشغال العمومية منذ 1998.',
    employeesRange: '201-500',
    verificationStatus: 'verified',
    phone: '0550120001',
  },
  {
    name: 'مؤسسة تجارية خاصة',
    sector: 'commerce',
    wilaya: 'وهران',
    description: 'مؤسسة تجارية متخصّصة في التوزيع بالجملة.',
    employeesRange: '11-50',
    verificationStatus: 'verified',
    phone: '0550120002',
  },
  {
    name: 'شركة الخدمات العامة',
    sector: 'services',
    wilaya: 'قسنطينة',
    description: 'خدمات إدارية ولوجستية للمؤسسات.',
    employeesRange: '51-200',
    verificationStatus: 'unverified',
    phone: '0550120003',
  },
  {
    name: 'شركة النقل الوطنية',
    sector: 'transport',
    wilaya: 'الجزائر العاصمة',
    description: 'نقل البضائع عبر كامل التراب الوطني.',
    employeesRange: '201-500',
    verificationStatus: 'verified',
    phone: '0550120004',
  },
  {
    name: 'مطعم سباحي',
    sector: 'hospitality',
    wilaya: 'بجاية',
    description: 'مطعم تقليدي جزائري.',
    employeesRange: '1-10',
    verificationStatus: 'unverified',
    phone: '0550120005',
  },
  {
    name: 'مصنع المواد الغذائية',
    sector: 'industry',
    wilaya: 'سيدي بلعباس',
    description: 'إنتاج وتحويل المواد الغذائية.',
    employeesRange: '201-500',
    verificationStatus: 'verified',
    phone: '0550120006',
  },
];

const OFFERS = [
  {
    companyIndex: 0,
    title: 'مهندس مدني',
    profession: 'مهندس مدني',
    sector: 'construction',
    wilaya: 'الجزائر العاصمة',
    contractType: 'full_time',
    salaryMin: 50000,
    salaryMax: 80000,
    description:
      'تبحث شركتنا عن مهندس مدني ذو خبرة لا تقل عن 3 سنوات في مجال البناء والمشاريع الهندسية. المهام تشمل متابعة الورشات، إعداد المخططات التنفيذية، والإشراف على فرق العمل.',
    skills: ['إتقان برامج التصميم الهندسي', 'العمل الجماعي', 'القدرة على حل المشكلات'],
    educationLevel: 'master',
    experienceLevel: 'mid',
    featured: true,
  },
  {
    companyIndex: 1,
    title: 'محاسب',
    profession: 'محاسب',
    sector: 'commerce',
    wilaya: 'وهران',
    contractType: 'full_time',
    salaryMin: 40000,
    salaryMax: 60000,
    description:
      'مطلوب محاسب لمسك الدفاتر المحاسبية، إعداد الميزانيات، ومتابعة التصريحات الجبائية. يُشترط إتقان برامج المحاسبة.',
    skills: ['المحاسبة العامة', 'إتقان الإعلام الآلي', 'الدقة والتنظيم'],
    educationLevel: 'licence',
    experienceLevel: 'mid',
  },
  {
    companyIndex: 2,
    title: 'مساعد إداري',
    profession: 'مساعد إداري',
    sector: 'services',
    wilaya: 'قسنطينة',
    contractType: 'full_time',
    salaryMin: 30000,
    salaryMax: 45000,
    description:
      'مطلوب مساعد إداري لتسيير الملفات، استقبال الزوار، وتنظيم المواعيد. يُشترط إتقان العربية والفرنسية.',
    skills: ['التنظيم', 'التواصل', 'إتقان Office'],
    educationLevel: 'bac',
    experienceLevel: 'junior',
  },
  {
    companyIndex: 3,
    title: 'سائق شاحنة',
    profession: 'سائق شاحنة',
    sector: 'transport',
    wilaya: 'الجزائر العاصمة',
    contractType: 'full_time',
    salaryMin: 35000,
    salaryMax: 50000,
    description:
      'مطلوب سائق شاحنة حاصل على رخصة صنف C مع خبرة لا تقل عن سنتين في النقل بين الولايات.',
    skills: ['رخصة سياقة صنف C', 'معرفة الطرق الوطنية', 'الالتزام بالمواعيد'],
    educationLevel: 'none',
    experienceLevel: 'mid',
  },
  {
    companyIndex: 4,
    title: 'طبّاخ',
    profession: 'طبّاخ',
    sector: 'hospitality',
    wilaya: 'بجاية',
    contractType: 'part_time',
    salaryMin: 25000,
    salaryMax: 40000,
    description:
      'مطعم تقليدي يبحث عن طبّاخ متمكّن من المطبخ الجزائري التقليدي، للعمل بدوام جزئي مساءً.',
    skills: ['المطبخ الجزائري', 'النظافة والسلامة الغذائية', 'السرعة في العمل'],
    educationLevel: 'vocational',
    experienceLevel: 'mid',
  },
  {
    companyIndex: 5,
    title: 'عامل إنتاج',
    profession: 'عامل إنتاج',
    sector: 'industry',
    wilaya: 'سيدي بلعباس',
    contractType: 'full_time',
    salaryMin: 28000,
    salaryMax: 38000,
    description:
      'مصنع للمواد الغذائية يوظّف عمال إنتاج للعمل ضمن فرق بنظام التناوب. التكوين مضمون عند التوظيف.',
    skills: ['العمل ضمن فريق', 'الانضباط', 'تحمّل العمل بالتناوب'],
    educationLevel: 'middle',
    experienceLevel: 'none',
  },
  {
    companyIndex: 0,
    title: 'تقني في الإعلام الآلي',
    profession: 'تقني إعلام آلي',
    sector: 'it',
    wilaya: 'الجزائر العاصمة',
    contractType: 'internship',
    salaryMin: 20000,
    salaryMax: 25000,
    description:
      'تربّص مدفوع الأجر لمدة 6 أشهر في مجال صيانة العتاد والشبكات، مع إمكانية التوظيف بعد التربّص.',
    skills: ['صيانة الحواسيب', 'الشبكات', 'الرغبة في التعلّم'],
    educationLevel: 'vocational',
    experienceLevel: 'none',
  },
  {
    companyIndex: 5,
    title: 'مسؤول موارد بشرية',
    profession: 'مسؤول موارد بشرية',
    sector: 'industry',
    wilaya: 'سيدي بلعباس',
    contractType: 'full_time',
    salaryMin: 55000,
    salaryMax: 75000,
    description:
      'مطلوب مسؤول موارد بشرية لتسيير ملفات العمال، التوظيف، والتكوين. خبرة 5 سنوات على الأقل.',
    skills: ['تسيير الموارد البشرية', 'قانون العمل الجزائري', 'التفاوض'],
    educationLevel: 'master',
    experienceLevel: 'senior',
    featured: true,
  },
];

async function seed() {
  await connectDB();

  // تُحذف كل المجموعات حتى تكون الحالة الابتدائية نظيفة تمامًا
  console.log('[seed] حذف البيانات السابقة...');
  await Promise.all([
    User.deleteMany({}),
    Profile.deleteMany({}),
    Company.deleteMany({}),
    JobOffer.deleteMany({}),
    Banner.deleteMany({}),
    Application.deleteMany({}),
    Conversation.deleteMany({}),
    Message.deleteMany({}),
    Notification.deleteMany({}),
    Report.deleteMany({}),
    SavedItem.deleteMany({}),
  ]);

  // حساب المشرف
  const admin = await User.create({
    fullName: 'مشرف المنصّة',
    phone: '0550000000',
    email: 'admin@bahth-dz.local',
    password: 'admin123456',
    role: ROLES.ADMIN,
    wilaya: 'الجزائر العاصمة',
    phoneVerified: true,
  });
  console.log('[seed] المشرف: 0550000000 / admin123456');

  // باحث عن عمل نموذجي (أحمد بن يوسف — كما في نموذج التصميم)
  const seeker = await User.create({
    fullName: 'أحمد بن يوسف',
    phone: '0555121456',
    email: 'ahmed@gmail.com',
    password: 'seeker123456',
    role: ROLES.SEEKER,
    wilaya: 'الجزائر العاصمة',
    phoneVerified: true,
  });

  await Profile.create({
    user: seeker._id,
    headline: 'تقني سامي في الإعلام الآلي',
    bio: 'تقني سامي في الإعلام الآلي، خبرة في صيانة الشبكات وتطوير تطبيقات الويب.',
    sector: 'it',
    profession: 'تقني إعلام آلي',
    educationLevel: 'vocational',
    yearsOfExperience: 4,
    skills: ['الشبكات', 'صيانة الحواسيب', 'HTML/CSS', 'العمل الجماعي'],
    languages: [
      { name: 'العربية', level: 'native' },
      { name: 'الفرنسية', level: 'fluent' },
      { name: 'الإنجليزية', level: 'good' },
    ],
    experiences: [
      {
        title: 'تقني في الإعلام الآلي',
        company: 'مؤسسة خاصة',
        wilaya: 'الجزائر العاصمة',
        startDate: new Date('2020-01-01'),
        endDate: new Date('2024-01-01'),
        description: 'صيانة العتاد والشبكات ودعم المستخدمين.',
      },
    ],
    educations: [
      {
        degree: 'تقني سامي في الإعلام الآلي',
        institution: 'المعهد الوطني للتكوين المهني',
        level: 'vocational',
        year: 2019,
      },
    ],
  });
  console.log('[seed] باحث عن عمل: 0555121456 / seeker123456');

  // المؤسسات وأصحابها
  const companies = [];
  for (const [i, data] of COMPANIES.entries()) {
    const owner = await User.create({
      fullName: `مسؤول ${data.name}`,
      phone: data.phone,
      email: `company${i + 1}@bahth-dz.local`,
      password: 'company123456',
      role: ROLES.COMPANY,
      wilaya: data.wilaya,
      phoneVerified: true,
    });

    const company = await Company.create({
      owner: owner._id,
      name: data.name,
      sector: data.sector,
      wilaya: data.wilaya,
      description: data.description,
      employeesRange: data.employeesRange,
      verificationStatus: data.verificationStatus,
      verifiedAt: data.verificationStatus === 'verified' ? new Date() : undefined,
      commercialRegister: data.verificationStatus === 'verified' ? `16/00-${1000 + i}` : undefined,
      contactPhone: data.phone,
    });

    companies.push({ company, owner });
  }
  console.log(`[seed] ${companies.length} مؤسسات (الدخول: 0550120001 / company123456)`);

  // العروض — منشورة ومصادق عليها، بتواريخ متدرّجة
  const now = Date.now();
  for (const [i, o] of OFFERS.entries()) {
    const { company, owner } = companies[o.companyIndex];
    await JobOffer.create({
      company: company._id,
      postedBy: owner._id,
      title: o.title,
      profession: o.profession,
      sector: o.sector,
      wilaya: o.wilaya,
      contractType: o.contractType,
      salaryMin: o.salaryMin,
      salaryMax: o.salaryMax,
      description: o.description,
      skills: o.skills,
      educationLevel: o.educationLevel,
      experienceLevel: o.experienceLevel,
      status: OFFER_STATUS.APPROVED,
      publishedAt: new Date(now - (i + 1) * 3600 * 1000),
      expiresAt: new Date(now + 30 * 864e5),
      reviewedBy: admin._id,
      reviewedAt: new Date(),
      featured: Boolean(o.featured),
      featuredUntil: o.featured ? new Date(now + 15 * 864e5) : undefined,
    });
  }

  // عرض واحد قيد المراجعة ليظهر في لوحة الإدارة
  await JobOffer.create({
    company: companies[2].company._id,
    postedBy: companies[2].owner._id,
    title: 'عون استقبال',
    profession: 'عون استقبال',
    sector: 'services',
    wilaya: 'قسنطينة',
    contractType: 'cdd',
    salaryMin: 25000,
    salaryMax: 32000,
    description: 'مطلوب عون استقبال للعمل في مقر الشركة، بعقد محدّد المدة قابل للتجديد.',
    skills: ['التواصل', 'الابتسامة', 'إتقان اللغتين'],
    educationLevel: 'bac',
    experienceLevel: 'junior',
    status: OFFER_STATUS.PENDING,
    expiresAt: new Date(now + 30 * 864e5),
  });

  console.log(`[seed] ${OFFERS.length} عروض منشورة + عرض واحد قيد المراجعة`);

  await Banner.create({
    title: 'مستقبلك المهني يبدأ من هنا',
    subtitle: 'اكتشف آلاف عروض العمل',
    ctaLabel: 'اكتشف آلاف عروض العمل',
    linkType: 'search',
    linkValue: '',
    active: true,
    order: 1,
  });

  console.log('[seed] تمت التعبئة بنجاح ✅');
  await mongoose.disconnect();
}

seed().catch(async (err) => {
  console.error('[seed] فشل:', err);
  await mongoose.disconnect();
  process.exit(1);
});
