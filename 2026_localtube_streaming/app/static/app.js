const form = document.getElementById("upload-form");
const status = document.getElementById("upload-status");

if (form) {
  form.addEventListener("submit", async (event) => {
    event.preventDefault();
    status.textContent = "업로드 중...";

    const formData = new FormData(form);
    const response = await fetch("/upload", {
      method: "POST",
      body: formData,
    });

    if (!response.ok) {
      const data = await response.json();
      status.textContent = `실패: ${data.detail || "unknown"}`;
      return;
    }

    status.textContent = "업로드 완료! 새로고침 후 영상 확인";
    form.reset();
    setTimeout(() => window.location.reload(), 700);
  });
}
