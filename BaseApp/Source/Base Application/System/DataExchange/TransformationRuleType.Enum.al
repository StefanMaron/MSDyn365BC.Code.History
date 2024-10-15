namespace System.IO;

enum 1237 "Transformation Rule Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Uppercase") { Caption = 'Uppercase'; }
    value(1; "Lowercase") { Caption = 'Lowercase'; }
    value(2; "Title Case") { Caption = 'Title Case'; }
    value(3; "Trim") { Caption = 'Trim'; }
    value(4; "Substring") { Caption = 'Substring'; }
    value(5; "Replace") { Caption = 'Replace'; }
    value(6; "Regular Expression - Replace") { Caption = 'Regular Expression - Replace'; }
    value(7; "Remove Non-Alphanumeric Characters") { Caption = 'Remove Non-Alphanumeric Characters'; }
    value(8; "Date Formatting") { Caption = 'Date Formatting'; }
    value(9; "Decimal Formatting") { Caption = 'Decimal Formatting'; }
    value(10; "Regular Expression - Match") { Caption = 'Regular Expression - Match'; }
    value(11; "Custom") { Caption = 'Custom'; }
    value(12; "Date and Time Formatting") { Caption = 'Date and Time Formatting'; }
    value(13; "Field Lookup") { Caption = 'Field Lookup'; }
    value(14; "Round") { Caption = 'Round'; }
    value(15; "Extract From Date") { Caption = 'Extract From Date'; }
}