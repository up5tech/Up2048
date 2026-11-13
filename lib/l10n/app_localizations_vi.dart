// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Up2048';

  @override
  String get homeSubtitle => 'Vuốt để trượt và gộp các ô. Chọn độ khó.';

  @override
  String get statsButton => 'Thống kê';

  @override
  String get settingsButton => 'Cài đặt';

  @override
  String get howToPlayButton => 'Cách chơi';

  @override
  String get difficultyEasy => 'Dễ';

  @override
  String get difficultyMedium => 'Trung bình';

  @override
  String get difficultyHard => 'Khó';

  @override
  String get difficultyVeryHard => 'Rất khó';

  @override
  String get taglineEasy => 'Bàn 5×5 với nhiều hỗ trợ';

  @override
  String get taglineMedium => 'Trải nghiệm cổ điển 4×4';

  @override
  String get taglineHard => 'Lộn xộn, thêm ô, xuất hiện ác ý';

  @override
  String get taglineVeryHard => 'Đá và xuất hiện thù địch';

  @override
  String badgeBoard(int size) {
    return 'Bàn $size×$size';
  }

  @override
  String badgeGoal(int target) {
    return 'Mục tiêu $target';
  }

  @override
  String badgeStones(int count) {
    return '$count đá';
  }

  @override
  String get badgeMeanSpawns => 'Xuất hiện ác ý';

  @override
  String badgeExtraTile(int n) {
    return 'Thêm ô mỗi $n';
  }

  @override
  String get badgeNoUndo => 'Không hoàn tác';

  @override
  String badgeUndo(int n) {
    return 'Hoàn tác ×$n';
  }

  @override
  String bestScoreLine(int score, int tile) {
    return 'Tốt nhất $score · Ô tốt nhất $tile';
  }

  @override
  String get notPlayedYet => 'Chưa chơi';

  @override
  String get continueButton => 'Tiếp tục';

  @override
  String get newGameButton => 'Ván mới';

  @override
  String get playButton => 'Chơi';

  @override
  String get settingsTitle => 'Cài đặt';

  @override
  String get soundEffects => 'Hiệu ứng âm thanh';

  @override
  String get vibration => 'Rung';

  @override
  String get vibrationSubtitle => 'Phản hồi rung khi gộp và thua';

  @override
  String get darkMode => 'Chế độ tối';

  @override
  String get reduceMotion => 'Giảm chuyển động';

  @override
  String get reduceMotionSubtitle => 'Bỏ qua hoạt ảnh trượt, gộp, xuất hiện';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String get languageEnglish => 'Tiếng Anh';

  @override
  String get languageVietnamese => 'Tiếng Việt';

  @override
  String get resetData => 'Xóa dữ liệu';

  @override
  String get resetDataSubtitle => 'Xóa ván đã lưu, thống kê và cài đặt';

  @override
  String get resetConfirmTitle => 'Xóa toàn bộ dữ liệu?';

  @override
  String get resetConfirmContent =>
      'Thao tác này xóa mọi ván đã lưu, thống kê và cài đặt.';

  @override
  String get cancel => 'Hủy';

  @override
  String get reset => 'Xóa';

  @override
  String get statsTitle => 'Thống kê';

  @override
  String get careerPoints => 'Điểm sự nghiệp';

  @override
  String get gamesPlayed => 'Số ván chơi';

  @override
  String get wins => 'Thắng';

  @override
  String get winRate => 'Tỉ lệ thắng';

  @override
  String get bestScore => 'Điểm tốt nhất';

  @override
  String get bestTile => 'Ô tốt nhất';

  @override
  String get totalMoves => 'Tổng số nước';

  @override
  String get howToPlayTitle => 'Cách chơi';

  @override
  String get difficultiesTitle => 'Độ khó';

  @override
  String get step1Title => 'Vuốt hoặc dùng phím mũi tên';

  @override
  String get step1Body => 'Tất cả các ô trượt theo hướng đó.';

  @override
  String get step2Title => 'Các ô bằng nhau gộp lại';

  @override
  String get step2Body =>
      'Hai ô 2 thành một ô 4, và giá trị gộp được tính điểm.';

  @override
  String get step3Title => 'Mỗi ô chỉ gộp một lần';

  @override
  String get step3Body => '[2, 2, 2, 2] trượt trái cho [4, 4], không phải 8.';

  @override
  String get step4Title => 'Đạt ô mục tiêu';

  @override
  String get step4Body =>
      'Giá trị mục tiêu thắng ván — bạn có thể tiếp tục chơi.';

  @override
  String get step5Title => 'Hết nước đi, thua';

  @override
  String get step5Body => 'Đá chia đường, hãy lập kế hoạch quanh chúng.';

  @override
  String get newGameConfirmTitle => 'Bắt đầu ván mới?';

  @override
  String get newGameConfirmContent => 'Tiến trình hiện tại sẽ bị mất.';

  @override
  String get tooltipNewGame => 'Ván mới';

  @override
  String get scoreLabel => 'ĐIỂM';

  @override
  String get movesLabel => 'NƯỚC';

  @override
  String get bestLabel => 'TỐT NHẤT';

  @override
  String undoLabel(String count) {
    return 'Hoàn tác ($count)';
  }

  @override
  String hintLabel(int count) {
    return 'Gợi ý ($count)';
  }

  @override
  String removeLabel(int count) {
    return 'Xóa ($count)';
  }

  @override
  String get cancelLabel => 'Hủy';

  @override
  String resultWinTitle(int tile) {
    return 'Bạn đã tạo $tile!';
  }

  @override
  String get gameOverTitle => 'Thua';

  @override
  String scoreLine(int score) {
    return 'Điểm: $score';
  }

  @override
  String movesLine(int moves) {
    return 'Nước: $moves';
  }

  @override
  String bestTileLine(int tile) {
    return 'Ô tốt nhất: $tile';
  }

  @override
  String get keepGoing => 'Tiếp tục chơi';

  @override
  String tileSemantics(int value, int row, int col) {
    return 'Ô $value, hàng $row, cột $col';
  }

  @override
  String stoneSemantics(int row, int col) {
    return 'Đá, hàng $row, cột $col';
  }
}
