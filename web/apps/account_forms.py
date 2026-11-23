from django import forms
from django.core.exceptions import ValidationError


class PasswordField(forms.CharField):
    def validate(self, value):
        super().validate(value)
        if len(value.encode("utf-8")) > 72:
            raise ValidationError("Mật khẩu tối đa 72 byte.")


class EmailForm(forms.Form):
    email = forms.EmailField(
        label="Email", max_length=254, widget=forms.EmailInput(attrs={"autocomplete": "email"}),
    )


class VerifyPasswordForm(forms.Form):
    code = forms.RegexField(
        label="Mã OTP", regex=r"^[0-9]{6}$", min_length=6, max_length=6,
        widget=forms.TextInput(attrs={"autocomplete": "one-time-code", "inputmode": "numeric"}),
        error_messages={"invalid": "Nhập mã gồm 6 chữ số."},
    )
    password = PasswordField(
        label="Mật khẩu mới", min_length=10, max_length=72, strip=False,
        widget=forms.PasswordInput(attrs={"autocomplete": "new-password"}),
    )
    password_confirmation = forms.CharField(
        label="Nhập lại mật khẩu", max_length=72, strip=False,
        widget=forms.PasswordInput(attrs={"autocomplete": "new-password"}),
    )

    def clean(self):
        data = super().clean()
        if "password" in data and "password_confirmation" in data and data["password"] != data["password_confirmation"]:
            self.add_error("password_confirmation", "Mật khẩu nhập lại chưa khớp.")
        return data


class RegisterForm(VerifyPasswordForm):
    full_name = forms.CharField(label="Họ và tên", max_length=120)
    username = forms.RegexField(
        label="Tên đăng nhập", min_length=3, max_length=64, regex=r"^[a-zA-Z0-9_.-]+$",
        widget=forms.TextInput(attrs={"autocomplete": "username"}),
        error_messages={"invalid": "Dùng chữ cái, chữ số, dấu chấm, gạch dưới hoặc gạch ngang."},
    )

    field_order = ["code", "full_name", "username", "password", "password_confirmation"]
