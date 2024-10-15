table 11514 "Swiss QR-Bill Reports"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Report Type"; Enum "Swiss QR-Bill Reports")
        {
            Caption = 'Name';
            Editable = false;
        }
        field(2; Enabled; Boolean)
        {
            Caption = 'Enabled';

            trigger OnValidate()
            begin
                ModifyReport();
            end;
        }
    }

    keys
    {
        key(PK; "Report Type")
        {
            Clustered = true;
        }
    }

    internal procedure InitBuffer()
    var
        Usage: Enum "Report Selection Usage";
    begin
        Add("Report Type"::"Posted Sales Invoice", Usage::"S.Invoice");
        Add("Report Type"::"Posted Service Invoice", Usage::"SM.Invoice");
    end;

    local procedure Add(ReportType: Enum "Swiss QR-Bill Reports"; UsageFilter: Enum "Report Selection Usage")
    var
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.SetRange("Report ID", Report::"Swiss QR-Bill Print");
        ReportSelections.SetRange(Usage, UsageFilter);
        "Report Type" := ReportType;
        Enabled := not ReportSelections.IsEmpty();
        Insert();
    end;

    internal procedure MapReportTypeToReportUsage() Result: Enum "Report Selection Usage"
    begin
        case "Report Type" of
            "Report Type"::"Posted Sales Invoice":
                exit(Result::"S.Invoice");
            "Report Type"::"Posted Service Invoice":
                exit(Result::"SM.Invoice");
            "Report Type"::"Issued Reminder":
                exit(Result::Reminder);
            "Report Type"::"Issued Finance Charge Memo":
                exit(Result::"Fin.Charge");
        end;
    end;

    local procedure ModifyReport()
    var
        ReportSelections: Record "Report Selections";
        ReportUsage: Enum "Report Selection Usage";
        Exists: Boolean;
    begin
        ReportUsage := MapReportTypeToReportUsage();

        with ReportSelections do begin
            SetRange(Usage, ReportUsage);
            SetRange("Report ID", Report::"Swiss QR-Bill Print");
            Exists := FindFirst();
            if not Exists and Enabled then begin
                SetRange("Report ID");
                NewRecord();
                Validate(Usage, ReportUsage);
                Validate("Report ID", Report::"Swiss QR-Bill Print");
                Insert();
            end;
            if Exists and not Enabled then
                Delete();
        end;
    end;
}
