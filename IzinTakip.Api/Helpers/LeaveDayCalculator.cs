namespace IzinTakip.Api.Helpers
{
    public class LeaveDayCalculator
    {
        // izin gün hesaplarken pazar günü hariç şekilde hesaplar
        public static int CountDaysExcludingSundays(DateTime start, DateTime end)
        {
            if (end.Date < start.Date) return 0;

            int days = 0;
            for (var d = start.Date; d <= end.Date; d = d.AddDays(1))
            {
                if (d.DayOfWeek != DayOfWeek.Sunday)
                    days++;
            }
            return days;
        }
    }
}
