table 477 "Report Inbox"
{
    Caption = 'Report Inbox';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Entry No.';
        }
        field(2; "User ID"; Text[65])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(3; "Report Output"; BLOB)
        {
            Caption = 'Report Output';
        }
        field(4; "Created Date-Time"; DateTime)
        {
            Caption = 'Created Date-Time';
            Editable = false;
        }
        field(5; "Job Queue Log Entry ID"; Guid)
        {
            Caption = 'Job Queue Log Entry ID';
            Editable = false;
        }
        field(6; "Output Type"; Option)
        {
            Caption = 'Output Type';
            Editable = false;
            OptionCaption = 'PDF,Word,Excel,Zip';
            OptionMembers = PDF,Word,Excel,Zip;
        }
        field(7; Description; Text[250])
        {
            Caption = 'Description';
            Editable = false;
        }
        field(8; "Report ID"; Integer)
        {
            Caption = 'Report ID';
            Editable = false;
        }
        field(9; "Report Name"; Text[250])
        {
            CalcFormula = Lookup (AllObjWithCaption."Object Caption" WHERE("Object Type" = CONST(Report),
                                                                           "Object ID" = FIELD("Report ID")));
            Caption = 'Report Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(10; Read; Boolean)
        {
            Caption = 'Read';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "User ID", "Created Date-Time")
        {
        }
    }

    fieldgroups
    {
    }

    var
        FileDownLoadTxt: Label 'Export';
        ReportIsEmptyMsg: Label 'The report is empty.';
        NoReportsToShowErr: Label 'There are no reports in the list.';

    procedure ShowReport()
    var
        Instr: InStream;
        Downloaded: Boolean;
        FileName: Text;
    begin
        if "Entry No." = 0 then
            Error(NoReportsToShowErr);

        CalcFields("Report Output", "Report Name");
        if not "Report Output".HasValue then begin
            Read := true;
            Modify;
            Commit();
            Message(ReportIsEmptyMsg);
            exit;
        end;
        if "Report Name" <> '' then
            FileName := DelChr("Report Name", '=', '/:*?"<>|') + Suffix
        else
            FileName := DelChr(Description, '=', '/:*?"<>|') + Suffix;

        "Report Output".CreateInStream(Instr);
        Downloaded := DownloadFromStream(Instr, FileDownLoadTxt, '', '', FileName);

        if not Read and Downloaded then begin
            Read := true;
            Modify;
        end;
    end;

    local procedure Suffix(): Text
    begin
        case "Output Type" of
            "Output Type"::PDF:
                exit('.pdf');
            "Output Type"::Word:
                exit('.docx');
            "Output Type"::Excel:
                exit('.xlsx');
            "Output Type"::Zip:
                exit('.zip');
        end;
    end;
}

