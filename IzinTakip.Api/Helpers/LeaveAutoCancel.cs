using IzinTakip.Api.Data;

namespace IzinTakip.Api.Helpers
{
    public class LeaveAutoCancel
    {

        // onay bekleyen günü geçmiş izinleri sistem otomatik iptal eder
        public static int CancelExpiredPending(AppDbContext context, DateTime todayTr)
        {
            var expired = context.LeaveRequests
                .Where(lr => lr.StatusId == 1 && !lr.IsCancelled && lr.StartDate.Date < todayTr)
                .ToList();

            foreach (var lr in expired)
            {
                lr.IsCancelled = true;
                lr.RejectionReason = "Tarih geçtiği için sistem tarafından iptal edildi.";
            }

            if (expired.Count > 0)
                context.SaveChanges();

            return expired.Count;
        }

    }
}
