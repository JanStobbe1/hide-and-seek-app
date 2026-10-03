export function validateGameSetup(body: Record<string, unknown>): string | null {
  // Missing fields remain valid for older installed clients and existing games.
  if (body.customQuestions !== undefined) {
    const questions = body.customQuestions;
    if (!Array.isArray(questions)) return "custom_questions_invalid";
    if (body.questionsEnabled !== false) {
      if (body.questionCount !== 3 && body.questionCount !== 5) return "question_count_invalid";
      if (questions.length !== body.questionCount || questions.some(q =>
        typeof q !== "string" || !q.trim() || q.trim().length > 160)) {
        return "custom_questions_invalid";
      }
      if (new Set(questions.map(q => q.trim().toLowerCase())).size !== questions.length) {
        return "custom_questions_duplicate";
      }
    } else if (questions.length !== 0) return "questions_disabled";
  }
  if (body.playBoundary !== undefined) {
    const p = body.playBoundary;
    if (!Array.isArray(p) || p.length < 3 || p.length > 32 || p.some(point =>
      !Array.isArray(point) || point.length !== 2 ||
      point.some(v => typeof v !== "number" || !Number.isFinite(v)) ||
      Math.abs(point[0]) > 85 || Math.abs(point[1]) > 180)) return "play_boundary_invalid";
    const cross = (a: number[], b: number[], c: number[]) =>
      (b[1]-a[1])*(c[0]-a[0]) - (b[0]-a[0])*(c[1]-a[1]);
    const onSegment = (a: number[], b: number[], c: number[]) =>
      Math.abs(cross(a,b,c)) < 1e-12 &&
      c[0] >= Math.min(a[0], b[0]) && c[0] <= Math.max(a[0], b[0]) &&
      c[1] >= Math.min(a[1], b[1]) && c[1] <= Math.max(a[1], b[1]);
    let area = 0;
    for (let i=0; i<p.length; i++) {
      const a = p[i], b = p[(i+1)%p.length];
      if (a[0] === b[0] && a[1] === b[1]) return "play_boundary_invalid";
      area += cross(p[0],a,b);
      for (let j=i+1; j<p.length; j++) {
        if (j === i+1 || (i === 0 && j === p.length-1)) continue;
        const c = p[j], d = p[(j+1)%p.length];
        if ((cross(a,b,c)*cross(a,b,d) < 0 && cross(c,d,a)*cross(c,d,b) < 0) ||
          onSegment(a,b,c) || onSegment(a,b,d) || onSegment(c,d,a) || onSegment(c,d,b)) {
          return "play_boundary_crossed";
        }
      }
    }
    if (Math.abs(area) < 1e-10) return "play_boundary_invalid";
  }
  return null;
}
