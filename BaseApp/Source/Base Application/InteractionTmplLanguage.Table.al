table 5103 "Interaction Tmpl. Language"
{
    Caption = 'Interaction Tmpl. Language';
    LookupPageID = "Interact. Tmpl. Languages";

    fields
    {
        field(1; "Interaction Template Code"; Code[10])
        {
            Caption = 'Interaction Template Code';
            Editable = false;
            TableRelation = "Interaction Template";
        }
        field(2; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(4; "Attachment No."; Integer)
        {
            Caption = 'Attachment No.';
        }
        field(5; "Custom Layout Code"; Code[20])
        {
            Caption = 'Custom Layout Code';
            TableRelation = "Custom Report Layout" WHERE("Report ID" = CONST(5084));

            trigger OnValidate()
            begin
                CalcFields("Custom Layout Description");
            end;
        }
        field(6; "Custom Layout Description"; Text[250])
        {
            CalcFormula = Lookup ("Custom Report Layout".Description WHERE(Code = FIELD("Custom Layout Code")));
            Caption = 'Custom Layout Description';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Interaction Template Code", "Language Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        RemoveAttachment(false);
    end;

    trigger OnRename()
    var
        InteractionTemplate: Record "Interaction Template";
    begin
        InteractionTemplate.Get("Interaction Template Code");
        if xRec."Language Code" <> "Language Code" then
            if InteractionTemplate."Language Code (Default)" = xRec."Language Code" then begin
                InteractionTemplate."Language Code (Default)" := "Language Code";
                InteractionTemplate.Modify();
            end;
    end;

    var
        AttachmentRecord: Record Attachment;
        ClientTypeManagement: Codeunit "Client Type Management";
        Text000: Label 'You have canceled the create process.';
        Text001: Label 'Replace existing attachment?';
        Text002: Label 'You have canceled the import process.';
        Text005: Label 'Export Attachment';

    procedure CreateAttachment()
    var
        Attachment: Record Attachment;
        InteractTmplLanguage: Record "Interaction Tmpl. Language";
        WordManagement: Codeunit WordManagement;
        NewAttachNo: Integer;
    begin
        if "Attachment No." <> 0 then begin
            if Attachment.Get("Attachment No.") then
                Attachment.TestField("Read Only", false);
            if not Confirm(Text001, false) then
                exit;
        end;

        if "Custom Layout Code" = '' then
            if ClientTypeManagement.GetCurrentClientType in [CLIENTTYPE::Web, CLIENTTYPE::Tablet, CLIENTTYPE::Phone] then begin
                if Attachment.ImportAttachmentFromClientFile('', false, false) then
                    NewAttachNo := Attachment."No.";
            end else
                NewAttachNo :=
                  WordManagement.CreateWordAttachment("Interaction Template Code" + ' ' + Description, "Language Code")
        else
            NewAttachNo := CreateHTMLCustomLayoutAttachment;

        if NewAttachNo <> 0 then begin
            if "Attachment No." <> 0 then
                RemoveAttachment(false);
            "Attachment No." := NewAttachNo;
            if InteractTmplLanguage.Get("Interaction Template Code", "Language Code") then
                Modify
            else
                Insert;
        end else
            Error(Text000);
    end;

    procedure CreateHTMLCustomLayoutAttachment(): Integer
    var
        Attachment: Record Attachment;
    begin
        Attachment.Init();
        Attachment."Storage Type" := Attachment."Storage Type"::Embedded;
        Attachment."File Extension" := 'HTML';
        Attachment.Insert(true);
        Attachment.WriteHTMLCustomLayoutAttachment('', "Custom Layout Code");
        exit(Attachment."No.");
    end;

    procedure OpenAttachment()
    var
        Attachment: Record Attachment;
    begin
        if "Attachment No." = 0 then
            exit;
        Attachment.Get("Attachment No.");
        Attachment.OpenAttachment("Interaction Template Code" + ' ' + Description, false, "Language Code");
    end;

    procedure CopyFromAttachment()
    var
        InteractTmplLanguage: Record "Interaction Tmpl. Language";
        Attachment: Record Attachment;
        AttachmentManagement: Codeunit AttachmentManagement;
        NewAttachNo: Integer;
    begin
        if Attachment.Get("Attachment No.") then
            Attachment.TestField("Read Only", false);

        if "Attachment No." <> 0 then begin
            if not Confirm(Text001, false) then
                exit;
            RemoveAttachment(false);
            "Attachment No." := 0;
            Modify;
            Commit();
        end;

        InteractTmplLanguage.SetFilter("Attachment No.", '<>%1', 0);
        if PAGE.RunModal(0, InteractTmplLanguage) = ACTION::LookupOK then begin
            NewAttachNo := AttachmentManagement.InsertAttachment(InteractTmplLanguage."Attachment No.");
            if NewAttachNo <> 0 then begin
                "Attachment No." := NewAttachNo;
                Modify;
            end;
        end;
    end;

    procedure ImportAttachment()
    var
        Attachment: Record Attachment;
    begin
        if "Attachment No." <> 0 then begin
            if Attachment.Get("Attachment No.") then
                Attachment.TestField("Read Only", false);
            if not Confirm(Text001, false) then
                exit;
        end;

        if Attachment.ImportAttachmentFromClientFile('', false, false) then begin
            "Attachment No." := Attachment."No.";
            Modify;
        end else
            Error(Text002);
    end;

    procedure ExportAttachment()
    var
        MarketingSetup: Record "Marketing Setup";
        TempBlob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
        FileName: Text[1024];
        FileFilter: Text;
        ExportToFile: Text;
    begin
        MarketingSetup.Get();
        ExportToFile := '';
        if not AttachmentRecord.Get("Attachment No.") then
            exit;

        case AttachmentRecord."Storage Type" of
            AttachmentRecord."Storage Type"::Embedded:
                begin
                    AttachmentRecord.CalcFields("Attachment File");
                    if AttachmentRecord."Attachment File".HasValue then begin
                        FileName := "Interaction Template Code" + '.' + AttachmentRecord."File Extension";
                        TempBlob.FromRecord(AttachmentRecord, AttachmentRecord.FieldNo("Attachment File"));
                        FileMgt.BLOBExport(TempBlob, FileName, true);
                    end;
                end;
            AttachmentRecord."Storage Type"::"Disk File":
                begin
                    if MarketingSetup."Attachment Storage Type" = MarketingSetup."Attachment Storage Type"::"Disk File" then
                        MarketingSetup.TestField("Attachment Storage Location");
                    FileFilter :=
                      UpperCase(AttachmentRecord."File Extension") +
                      ' (*.' + AttachmentRecord."File Extension" + ')|*.' + AttachmentRecord."File Extension";
                    ExportToFile := "Interaction Template Code" + '.' + AttachmentRecord."File Extension";
                    FileMgt.DownloadHandler(
                      AttachmentRecord."Storage Pointer" + '\' + Format(AttachmentRecord."No.") + '.' + AttachmentRecord."File Extension",
                      Text005, '', FileFilter, ExportToFile);
                end;
        end;
    end;

    procedure RemoveAttachment(Prompt: Boolean)
    var
        Attachment: Record Attachment;
    begin
        if Attachment.Get("Attachment No.") then
            if Attachment.RemoveAttachment(Prompt) then begin
                "Attachment No." := 0;
                Modify;
            end;
    end;
}

