namespace IzinTakip.Api.Helpers
{
    public class DateTimeProvider
    {

        private static readonly TimeZoneInfo TrTz = TimeZoneInfo.FindSystemTimeZoneById("Turkey Standard Time");

        public static DateTime TodayTr()
        {
            var nowTr = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, TrTz);
            return nowTr.Date;
        }
    }
}
