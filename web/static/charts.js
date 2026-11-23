if (window.Chart) {
  const activity = document.getElementById("activity-data");
  if (activity) {
    const records = JSON.parse(activity.textContent);
    new Chart(document.getElementById("activity-chart"), {
      type: "bar",
      data: {
        labels: records.map((row) => row.ngay),
        datasets: [{
          label: "Lượt nộp",
          data: records.map((row) => Number(row.luot)),
          backgroundColor: "#5869de",
          borderRadius: 5,
          maxBarThickness: 35
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {legend: {display: false}},
        scales: {
          x: {grid: {display: false}},
          y: {beginAtZero: true, ticks: {precision: 0}, grid: {color: "#edf0f8"}}
        }
      }
    });
  }

  const errors = document.getElementById("errors-data");
  if (errors) {
    const records = JSON.parse(errors.textContent);
    new Chart(document.getElementById("errors-chart"), {
      type: "bar",
      data: {
        labels: records.map((row) => "Test " + row.thu_tu),
        datasets: [{
          label: "Số học viên sai",
          data: records.map((row) => Number(row.so_nguoi_sai)),
          backgroundColor: "#5869de",
          borderRadius: 5,
          maxBarThickness: 22
        }]
      },
      options: {
        indexAxis: "y",
        responsive: true,
        maintainAspectRatio: false,
        plugins: {legend: {display: false}},
        scales: {
          x: {beginAtZero: true, ticks: {precision: 0}, grid: {color: "#edf0f8"}},
          y: {grid: {display: false}}
        }
      }
    });
  }
}
