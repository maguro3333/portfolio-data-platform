import { ButtonLink } from "@/components/ui/button-link";

export default function NotFound() {
  return (
    <section className="px-5 py-24 md:px-8 md:py-32">
      <div className="mx-auto max-w-2xl text-center">
        <p className="font-mono text-xs uppercase tracking-[0.18em] text-terracotta">
          404 / Not found
        </p>
        <h1 className="mt-6 font-display text-4xl font-semibold md:text-5xl">
          ページが見つかりません。
        </h1>
        <p className="mt-5 text-base leading-8 text-ink-muted">
          URLが変更されたか、まだ公開されていないページです。
        </p>
        <div className="mt-8">
          <ButtonLink href="/">ホームへ戻る</ButtonLink>
        </div>
      </div>
    </section>
  );
}
