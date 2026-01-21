# <h1>Izin-Takip</h1>
Modern bir izin talep ve onay yönetim sistemi. Mobil (Flutter) + Backend (.NET Web API Cloud Azure) + Cloud DB(MSSQL) mimarisiyle geliştirilmiştir.  Bu proje bir case study olarak tasarlanmış olup, gerçek hayattaki bir şirket senaryosunu uçtan uca ele alır.
<p> <strong>Dikkat !!! Api Cloud öğrenci kimliğiyle ücretsiz oluşturulduğundan uygulamaya ilk girişte Api uyku modunda olabilir uygulamayı kapa aç yapıp tekrar giriş yapmalısınız. !!! </strong></p>

Proje Amacı

Şirket çalışanlarının:

İzin talebi oluşturabilmesi

Taleplerini güncelleyebilmesi / iptal edebilmesi

Yöneticilerin izinleri onaylaması / reddetmesi

İzin haklarının ve sayılarının otomatik takip edilmesi

ve tüm bu sürecin departman temalı, rol bazlı, güvenli ve kullanıcı dostu bir mobil uygulama üzerinden yönetilmesi amaçlanmıştır.

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

<h3> Genel Mimari </h3>

Flutter Mobile App
        ↓
.NET Web API (Azure Cloud) (JWT Authentication)
        ↓
SQL Server (Azure DB)

* Mobil: Flutter

* Backend: ASP.NET Core Web API (JWT, EF Core, N-Katmanlı Mimari)

* Auth: JWT (Role + Custom Claims)

* Database: MSSQL (Azure DB)

* Cloud: Azure App Service (Always On aktif)
  
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

<h3>Roller ve Yetkiler</h3>

Employee (Çalışan)

Kendi izin taleplerini görüntüler

Yeni izin talebi oluşturur

Sadece bekleyen talepleri güncelleyebilir / iptal edebilir

Aynı gün için tekrar izin talep edilemez, izin hakkından fazla izin talep edilemez

Dashboard’da:

Toplam izin hakkı

Kullanılan / kalan gün

Bekleyen – onaylanan – reddedilen talepler


Manager (Yönetici)

Kendi taleplerini çalışan gibi yönetir

Ek olarak:

Onay kutusunda bekleyen talepleri görür

İzinleri onaylar / reddeder

Red için açıklama girmek zorundadır

Departmanındaki çalışanları listeler

Departman izin geçmişini görüntüler

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

<h3>Dashboard Özellikleri</h3>

Employee Dashboard

Toplam yıllık izin (14 gün)

Kalan izin

Bekleyen talepler

Onaylanan talepler

Manager Dashboard

Bekleyen onay sayısı

Bugün izinde olan çalışan sayısı

Son 5 izin talebi (departman bazlı)

Yönetici bu ekrandan hızlıca bekleyen talebe gidip onay/ret yapabilir

Bu ekranda bugün kaç çalışan izinli görebilir

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

<h3>İzin Kuralları</h3>

Yıllık izin hakkı: 14 gün

Pazar günleri izin süresine dahil edilmez

endDate - startDate + 1 mantığı kullanılır

Geçmiş tarihler için izin oluşturulamaz

Tarihi geçen bekleyen talepler otomatik iptal edilir

Aynı gün için çakışan izin talebi oluşturulamaz

Kalan izin yetersizse backend hata döner (UI’da gösterilir)

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

<h3>Güvenlik</h3>

JWT Authentication

Role-based authorization

Ek olarak:

employeeId

isManager
claim’leri kullanılır

Backend tarafında yetki kontrolleri zorunlu,
UI tarafında ise kullanıcı deneyimi için ek kısıtlar uygulanmıştır.

Güvenlik hem backend hem ui tarafı için düşünülmüştür.

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

<h3>Mobil Uygulama Özellikleri</h3>

Flutter version: Channel stable, 3.38.7

Material 3 tasarım

Pull-to-Refresh + Haptic Feedback

Loading / Empty / Error state’leri

Animated Status Chips:

Bekleyen → Pulse

Onaylandı → Check animasyonu

Reddedildi → Fade / Shake

Manager & Employee için farklı navigation

Timeout + retry mekanizmalı login

Azure uykuya geçme problemi için health endpoint ping (Başlangıç için öğrenci ücretsiz cloud oluşturuldu bu hatadan kaynaklı geçici B1 Azure planına geçildi)

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Gerçek Android cihazlarda test edildi

Farklı kullanıcı rollerinde senaryo testleri yapıldı

Edge case’ler:

Yetersiz izin

Çakışan tarih

Yetkisiz erişim

Timeout / network problemleri

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

<h3>Cloud & Deployment</h3>

Azure App Service (B1 Plan)

Always On aktif

MSSQL Azure Database

Backend ve DB tamamen cloud üzerinde

Lokal kurulum gerektirmez

Sadece apk telefona kurulup kullanılabilir

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

<h3>Repo Yapısı (Temeli)</h3>

/backend

  └── Controllers
  
  └── Data (Db Context)
  
  └── Models (└── DTOs)
  
  └── Helpers

/mobile

  └── core
  
  └── features
      └── data
          └── models
          └── service
      └── ui

      
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

<h3>Personel Ağacı Mantığı</h3>

Yönetici, işçi, yazılımcı, insan kaynakları farketmeksizin herkes bir personeldir ve herkesin bir personel kartı vardır. Her personelin ait olduğu bir departman vardır ve her departmanın yöneticisi vardır.

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

<h3>Veritabanı Yapısı (Cloud Db)</h3>

-> Azure SQL Database

-> ilk etapta öğrenci kimliğimle ücretsiz bir plan uyguladım sonrasında öğrencilikten dolayı yine ücretsiz olabilecek B1 planına geçiş yaptım. Bölge olarak "Germany West Central" seçmemin sebebi de budur.

-> Sorgular için basit ve hızlı olan yol Azure Portal Query Editör kullandım

  Tablolar:
  
  -> Departments: departman isimlerini ve departman yöneticisinin id'sini tutar
  
  -> EmployeeAnnualLeave: Çalışanın o yıl izin hak sayısını, ne kadar kullanıldığını vs. tutar
  
  -> Employees: Çalışan bilgilerini, hangi departmanda olduğunu ve departmanda yönetici olup olmadığı gibi bilgileri tutar
  
  -> LeaveRequests: izin isteklerini tutar
  
  -> LeaveStatus: izin istek durum tiplerini tutar
  
  -> LeaveTypes: izin istek tiplerini tutar
  
  -> Users: kullanıcı giriş bilgilerini tutar ve çalışan id'si ile eşleştirir
  
  ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

 <h3> Proje için geliştirme önerileri</h3>
  
  ** Veritabanında özel günler tutulabilir (23 nisan, kurban bayramı vs.) ve bu özel günler izin talep işlemlerinde izinden düşülmeyecek gün olarak ayarlanabilir
  
  ** Raporlu gibi bazı izin istek tiplerinin izin hakkı sayısından düşülmeyecek şekilde ayarlanabilir.
  
  ** Profil sekmesi eklenebilir, kişi profilini güncelleyebilir.
  
  ** Bildirim sistemi devreye alınabilir, yönetici için personeli talep oluşturunca haber verilebilir, normal personel için de oluşturduğu talep ile ilgili bir gelişme olursa haber verilebilir
