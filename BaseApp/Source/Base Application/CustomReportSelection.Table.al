table 9657 "Custom Report Selection"
{
    Caption = 'Custom Report Selection';

    fields
    {
        field(1; "Source Type"; Integer)
        {
            Caption = 'Source Type';
        }
        field(2; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            TableRelation = IF ("Source Type" = CONST(18)) Customer."No."
            ELSE
            IF ("Source Type" = CONST(23)) Vendor."No.";
        }
        field(3; Usage; Option)
        {
            Caption = 'Usage';
            OptionCaption = 'S.Quote,S.Order,S.Invoice,S.Cr.Memo,S.Test,P.Quote,P.Order,P.Invoice,P.Cr.Memo,P.Receipt,P.Ret.Shpt.,P.Test,B.Stmt,B.Recon.Test,B.Check,Reminder,Fin.Charge,Rem.Test,F.C.Test,Prod.Order,S.Blanket,P.Blanket,M1,M2,M3,M4,Inv1,Inv2,Inv3,SM.Quote,SM.Order,SM.Invoice,SM.Credit Memo,SM.Contract Quote,SM.Contract,SM.Test,S.Return,P.Return,S.Shipment,S.Ret.Rcpt.,S.Work Order,Invt.Period Test,SM.Shipment,S.Test Prepmt.,P.Test Prepmt.,S.Arch.Quote,S.Arch.Order,P.Arch.Quote,P.Arch.Order,S.Arch.Return,P.Arch.Return,Asm.Order,P.Asm.Order,S.Order Pick Instruction,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,P.V.Remit.,C.Statement,V.Remittance,JQ,S.Invoice Draft,Pro Forma S. Invoice,S.Arch.Blanket,P.Arch.Blanket,Phys.Invt.Order Test,Phys.Invt.Order,P.Phys.Invt.Order,Phys.Invt.Rec.,P.Phys.Invt.Rec.';
            OptionMembers = "S.Quote","S.Order","S.Invoice","S.Cr.Memo","S.Test","P.Quote","P.Order","P.Invoice","P.Cr.Memo","P.Receipt","P.Ret.Shpt.","P.Test","B.Stmt","B.Recon.Test","B.Check",Reminder,"Fin.Charge","Rem.Test","F.C.Test","Prod.Order","S.Blanket","P.Blanket",M1,M2,M3,M4,Inv1,Inv2,Inv3,"SM.Quote","SM.Order","SM.Invoice","SM.Credit Memo","SM.Contract Quote","SM.Contract","SM.Test","S.Return","P.Return","S.Shipment","S.Ret.Rcpt.","S.Work Order","Invt.Period Test","SM.Shipment","S.Test Prepmt.","P.Test Prepmt.","S.Arch.Quote","S.Arch.Order","P.Arch.Quote","P.Arch.Order","S.Arch.Return","P.Arch.Return","Asm.Order","P.Asm.Order","S.Order Pick Instruction",,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,"P.V.Remit.","C.Statement","V.Remittance",JQ,"S.Invoice Draft","Pro Forma S. Invoice","S.Arch.Blanket","P.Arch.Blanket","Phys.Invt.Order Test","Phys.Invt.Order","P.Phys.Invt.Order","Phys.Invt.Rec.","P.Phys.Invt.Rec.";
        }
        field(4; Sequence; Integer)
        {
            AutoIncrement = true;
            Caption = 'Sequence';
        }
        field(5; "Report ID"; Integer)
        {
            Caption = 'Report ID';
            TableRelation = AllObjWithCaption."Object ID" WHERE("Object Type" = CONST(Report));

            trigger OnValidate()
            begin
                CalcFields("Report Caption");
                if ("Report ID" = 0) or ("Report ID" <> xRec."Report ID") then begin
                    Validate("Custom Report Layout Code", '');
                    Validate("Email Body Layout Code", '');
                end;
            end;
        }
        field(6; "Report Caption"; Text[250])
        {
            CalcFormula = Lookup (AllObjWithCaption."Object Caption" WHERE("Object Type" = CONST(Report),
                                                                           "Object ID" = FIELD("Report ID")));
            Caption = 'Report Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7; "Custom Report Layout Code"; Code[20])
        {
            Caption = 'Custom Report Layout Code';
            TableRelation = "Custom Report Layout" WHERE(Code = FIELD("Custom Report Layout Code"));

            trigger OnValidate()
            begin
                CalcFields("Custom Report Description");
            end;
        }
        field(8; "Custom Report Description"; Text[250])
        {
            CalcFormula = Lookup ("Custom Report Layout".Description WHERE(Code = FIELD("Custom Report Layout Code")));
            Caption = 'Custom Report Description';
            Editable = false;
            FieldClass = FlowField;
        }
        field(9; "Send To Email"; Text[200])
        {
            Caption = 'Send To Email';

            trigger OnValidate()
            var
                MailManagement: Codeunit "Mail Management";
            begin
                if "Send To Email" <> '' then
                    MailManagement.CheckValidEmailAddresses("Send To Email");
            end;
        }
        field(19; "Use for Email Attachment"; Boolean)
        {
            Caption = 'Use for Email Attachment';
            InitValue = true;

            trigger OnValidate()
            begin
                if not "Use for Email Body" then
                    Validate("Email Body Layout Code", '');
            end;
        }
        field(20; "Use for Email Body"; Boolean)
        {
            Caption = 'Use for Email Body';

            trigger OnValidate()
            begin
                if not "Use for Email Body" then
                    Validate("Email Body Layout Code", '');
            end;
        }
        field(21; "Email Body Layout Code"; Code[20])
        {
            Caption = 'Email Body Layout Code';
            TableRelation = "Custom Report Layout" WHERE(Code = FIELD("Email Body Layout Code"),
                                                          "Report ID" = FIELD("Report ID"));

            trigger OnValidate()
            begin
                if "Email Body Layout Code" <> '' then
                    TestField("Use for Email Body", true);
                CalcFields("Email Body Layout Description");
            end;
        }
        field(22; "Email Body Layout Description"; Text[250])
        {
            CalcFormula = Lookup ("Custom Report Layout".Description WHERE(Code = FIELD("Email Body Layout Code")));
            Caption = 'Email Body Layout Description';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Source Type", "Source No.", Usage, Sequence)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        TestField("Report ID");
        CheckEmailBodyUsage;
    end;

    trigger OnModify()
    begin
        TestField("Report ID");
        CheckEmailBodyUsage;
    end;

    var
        EmailBodyIsAlreadyDefinedErr: Label 'An email body is already defined for %1.', Comment = '%1 = Usage, for example Sales Invoice';
        CannotBeUsedAsAnEmailBodyErr: Label 'Report %1 uses the %2, which cannot be used as an email body.', Comment = '%1 = Report ID,%2 = Type';
        TargetEmailAddressErr: Label 'The target email address has not been specified in %1.', Comment='%1 - RecordID';

    procedure InitUsage()
    begin
        Usage := xRec.Usage;
    end;

    procedure FilterReportUsage(NewSourceType: Integer; NewSourceNo: Code[20]; NewUsage: Option)
    begin
        Reset;
        SetRange("Source Type", NewSourceType);
        SetRange("Source No.", NewSourceNo);
        SetRange(Usage, NewUsage);
    end;

    procedure FilterEmailBodyUsage(NewSourceType: Integer; NewSourceNo: Code[20]; NewUsage: Option)
    begin
        FilterReportUsage(NewSourceType, NewSourceNo, NewUsage);
        SetRange("Use for Email Body", true);
    end;

    local procedure CheckEmailBodyUsage()
    var
        CustomReportSelection: Record "Custom Report Selection";
        ReportLayoutSelection: Record "Report Layout Selection";
    begin
        if "Use for Email Body" then begin
            CustomReportSelection.FilterEmailBodyUsage("Source Type", "Source No.", Usage);
            CustomReportSelection.SetFilter(Sequence, '<>%1', Sequence);
            if not CustomReportSelection.IsEmpty then
                Error(EmailBodyIsAlreadyDefinedErr, Usage);

            if "Email Body Layout Code" = '' then
                if ReportLayoutSelection.GetDefaultType("Report ID") =
                   ReportLayoutSelection.Type::"RDLC (built-in)"
                then
                    Error(CannotBeUsedAsAnEmailBodyErr, "Report ID", ReportLayoutSelection.Type);
        end;
    end;

    local procedure LookupCustomReportLayout(CurrentLayoutCode: Code[20]): Code[20]
    var
        CustomReportLayout: Record "Custom Report Layout";
    begin
        if CustomReportLayout.LookupLayoutOK("Report ID") then
            exit(CustomReportLayout.Code);

        exit(CurrentLayoutCode);
    end;

    procedure LookupCustomReportDescription()
    begin
        Validate("Custom Report Layout Code", LookupCustomReportLayout("Custom Report Layout Code"));
    end;

    procedure LookupEmailBodyDescription()
    begin
        Validate("Email Body Layout Code", LookupCustomReportLayout("Custom Report Layout Code"));
    end;

    [Scope('OnPrem')]
    procedure CheckEmailSendTo()
    var
        ErrorMessageManagement: Codeunit "Error Message Management";
        ErrorMessage: Text[1024];
    begin
        if "Send To Email" <> '' then
            exit;

        ErrorMessage := StrSubstNo(TargetEmailAddressErr, RecordId);
        ErrorMessageManagement.LogError(Rec,ErrorMessage, '');
    end;
}

