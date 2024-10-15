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
        DummyReportSelections: Record "Report Selections";
    begin
        Add("Report Type"::"Posted Sales Invoice", DummyReportSelections.Usage::"S.Invoice");
        Add("Report Type"::"Posted Service Invoice", DummyReportSelections.Usage::"SM.Invoice");
    end;

    local procedure Add(ReportType: Enum "Swiss QR-Bill Reports"; UsageFilter: Option)
    var
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.SetRange("Report ID", Report::"Swiss QR-Bill Print");
        ReportSelections.SetRange(Usage, UsageFilter);
        "Report Type" := ReportType;
        Enabled := not ReportSelections.IsEmpty();
        Insert();
    end;

    internal procedure MapReportTypeToReportUsage(): Integer
    var
        DummyReportSelections: Record "Report Selections";
    begin
        case "Report Type" of
            "Report Type"::"Posted Sales Invoice":
                exit(DummyReportSelections.Usage::"S.Invoice");
            "Report Type"::"Posted Service Invoice":
                exit(DummyReportSelections.Usage::"SM.Invoice");
            "Report Type"::"Issued Reminder":
                exit(DummyReportSelections.Usage::Reminder);
            "Report Type"::"Issued Finance Charge Memo":
                exit(DummyReportSelections.Usage::"Fin.Charge");
        end;
    end;

    local procedure ModifyReport()
    var
        ReportSelections: Record "Report Selections";
        ReportUsage: Option;
        Exists: Boolean;
    begin
        ReportUsage := MapReportTypeToReportUsage();

        ReportSelections.SetRange(Usage, ReportUsage);
        ReportSelections.SetRange("Report ID", Report::"Swiss QR-Bill Print");
        Exists := ReportSelections.FindFirst();
        if not Exists and Enabled then begin
            ReportSelections.SetRange("Report ID");
            ReportSelections.NewRecord();
            ReportSelections.Validate(Usage, ReportUsage);
            ReportSelections.Validate("Report ID", Report::"Swiss QR-Bill Print");
            ReportSelections.Insert();
        end;
        if Exists and not Enabled then
            ReportSelections.Delete();
    end;
}
