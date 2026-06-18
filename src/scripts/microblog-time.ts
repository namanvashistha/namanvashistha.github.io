// Re-render microblog timestamps in the visitor's local timezone.
// Build output formats `createdAt` in the build machine's timezone (UTC on CI);
// here we reformat from the absolute instant in the `datetime` attribute so each
// reader sees their own local time. Runs on every View Transitions navigation.
function localizeTimes(): void {
  const els = document.querySelectorAll<HTMLTimeElement>('time[data-localtime]');
  els.forEach((el) => {
    const iso = el.getAttribute('datetime');
    if (!iso) return;
    const date = new Date(iso);
    if (Number.isNaN(date.getTime())) return;

    const opts: Intl.DateTimeFormatOptions =
      el.dataset.localtime === 'full'
        ? { dateStyle: 'full', timeStyle: 'short' }
        : { dateStyle: 'medium', timeStyle: 'short' };

    // No `timeZone` option => the runtime's local zone; 'en-GB' keeps the format.
    el.textContent = date.toLocaleString('en-GB', opts);
  });
}

document.addEventListener('astro:page-load', localizeTimes);
