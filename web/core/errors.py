def database_message(error):
    code = error.args[0] if error.args else None
    if code == 1644:
        return error.args[1]
    return {
        1048: "Cần nhập đầy đủ các trường bắt buộc.",
        1062: "Dữ liệu đã tồn tại.",
        1264: "Giá trị số nằm ngoài khoảng cho phép.",
        1265: "Giá trị đã chọn không hợp lệ.",
        1292: "Ngày, giờ hoặc giá trị nhập không đúng định dạng.",
        1366: "Giá trị nhập không đúng định dạng.",
        1406: "Nội dung dài hơn giới hạn.",
        1451: "Dữ liệu đang được tham chiếu nên chưa thể xóa.",
        1452: "Đối tượng tham chiếu không tồn tại hoặc chưa được phân công.",
        3819: "Giá trị không thỏa ràng buộc của cơ sở dữ liệu.",
        1205: "Dữ liệu đang được xử lý. Hãy thử lại.",
        1213: "Có thao tác đồng thời trên cùng dữ liệu. Hãy thử lại.",
    }.get(code, "MySQL không thể hoàn thành thao tác này.")
