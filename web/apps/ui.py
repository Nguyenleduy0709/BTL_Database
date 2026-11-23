from collections.abc import Callable
from dataclasses import dataclass
from datetime import date, datetime

from django import forms
from django.contrib import messages
from django.db import DatabaseError
from django.http import Http404
from django.shortcuts import redirect, render
from django.urls import reverse

from core.db import fetch_one
from core.errors import database_message

STATUS = {
    "DAT": "Đạt", "CHUA_DAT": "Chưa đạt", "CHUA_NOP": "Chưa nộp", "CHO_CHAM": "Chờ chấm",
    "DA_CHAM": "Đã chấm", "LOI_BIEN_DICH": "Lỗi biên dịch",
    "MO_DANG_KY": "Mở đăng ký", "DANG_HOC": "Đang học", "KET_THUC": "Đã kết thúc", "HUY": "Đã hủy",
    "HOAN_THANH": "Hoàn thành", "DA_HUY": "Đã hủy", "CO_MAT": "Có mặt", "MUON": "Đi muộn",
    "VANG_CO_PHEP": "Vắng có phép", "VANG": "Vắng", "CHINH": "Giảng viên chính", "TRO_GIANG": "Trợ giảng",
    "NHAP": "Bản nháp", "CONG_BO": "Công bố", "NGUNG": "Ngừng", "HOAT_DONG": "Hoạt động",
    "KHOA": "Đã khóa", "DE": "Dễ", "TRUNG_BINH": "Trung bình", "KHO": "Khó",
    "CO_BAN": "Cơ bản", "TRUNG_CAP": "Trung cấp", "NANG_CAO": "Nâng cao", "XUAT_SAC": "Xuất sắc",
    "AC": "AC", "WA": "WA", "TLE": "TLE", "MLE": "MLE", "RE": "RE",
}
SUCCESS = {"DAT", "DA_CHAM", "CONG_BO", "HOAT_DONG", "CO_MAT", "AC", "HOAN_THANH", "MO_DANG_KY"}
WARNING = {"CHUA_DAT", "CHO_CHAM", "MUON", "VANG_CO_PHEP", "TRUNG_BINH"}
DANGER = {"HUY", "DA_HUY", "LOI_BIEN_DICH", "KHOA", "VANG", "WA", "TLE", "MLE", "RE"}


@dataclass(frozen=True)
class Link:
    label: str
    url: str


@dataclass(frozen=True)
class Badge:
    label: str
    color: str


def link(label, route, *args):
    return Link(label, reverse(route, args=args))


def status(value):
    color = "success" if value in SUCCESS else "warning" if value in WARNING else "danger" if value in DANGER else "neutral"
    return Badge(STATUS.get(value, value), color) if value else "—"


def percent(value):
    return "Chưa có dữ liệu" if value is None else f"{value:.2f}".rstrip("0").rstrip(".") + "%"


def money(value):
    return f"{value:,.0f}".replace(",", ".") + " ₫"


def require_row(sql, params):
    row = fetch_one(sql, params)
    if row is None:
        raise Http404
    return row


def table(title, columns, rows, empty="Chưa có dữ liệu."):
    def cell(row, column):
        if isinstance(column, Callable):
            return column(row)
        value = row.get(column)
        if isinstance(value, datetime):
            return value.strftime("%d/%m/%Y %H:%M")
        if isinstance(value, date):
            return value.strftime("%d/%m/%Y")
        return "—" if value is None else value

    return {"title": title, "headers": list(columns),
            "rows": [[cell(row, column) for column in columns.values()] for row in rows], "empty": empty}


def page(request, title, section, *, tables=(), actions=(), **context):
    return render(request, "page.html", {
        "title": title, "section": section, "tables": tables, "actions": actions, **context,
    })


def options(rows, value, label):
    return [(row[value], row[label]) for row in rows]


def select(label, choices, required=True):
    return forms.TypedChoiceField(label=label, choices=[("", "Chọn…"), *choices],
                                  coerce=int, empty_value=None, required=required)


def enum(label, keys, choices=STATUS):
    return forms.ChoiceField(label=label, choices=[(key, choices[key]) for key in keys])


def text(label, length=160, required=True):
    return forms.CharField(label=label, max_length=length, required=required)


def area(label, length=15000, required=True, css_class="", *, strip=True):
    return forms.CharField(label=label, max_length=length, required=required, strip=strip,
                           widget=forms.Textarea(attrs={"rows": 4, "class": css_class}))


def time_field(label):
    return forms.DateTimeField(label=label, input_formats=["%Y-%m-%dT%H:%M"],
                               widget=forms.DateTimeInput(format="%Y-%m-%dT%H:%M", attrs={"type": "datetime-local"}))


def day_field(label):
    return forms.DateField(label=label, widget=forms.DateInput(format="%Y-%m-%d", attrs={"type": "date"}))


def form_page(request, title, section, fields, save, back, *, initial=None, description="", submit="Lưu", tables=()):
    form = forms.Form(request.POST if request.method == "POST" else None, initial=initial)
    form.fields.update(fields)
    if form.is_bound and form.is_valid():
        try:
            target = save(form.cleaned_data)
        except DatabaseError as error:
            form.add_error(None, database_message(error))
        else:
            messages.success(request, "Đã lưu thay đổi.")
            return redirect(target or back.url)
    return render(request, "form.html", {
        "title": title, "section": section, "form": form, "back": back,
        "description": description, "submit": submit, "tables": tables,
    })


def action(request, callback, target, success):
    try:
        callback()
    except DatabaseError as error:
        messages.error(request, database_message(error))
    else:
        messages.success(request, success)
    return redirect(target)
