table 5077 "Segment Line"
{
    Caption = 'Segment Line';

    fields
    {
        field(1; "Segment No."; Code[20])
        {
            Caption = 'Segment No.';
            TableRelation = "Segment Header";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Contact No."; Code[20])
        {
            Caption = 'Contact No.';
            TableRelation = Contact;

            trigger OnValidate()
            var
                SegInteractLanguage: Record "Segment Interaction Language";
                Attachment: Record Attachment;
                InteractTmpl: Record "Interaction Template";
            begin
                InitLine;

                if Cont.Get("Contact No.") then begin
                    "Language Code" := FindLanguage("Interaction Template Code", Cont."Language Code");
                    "Contact Company No." := Cont."Company No.";
                    "Contact Alt. Address Code" := Cont.ActiveAltAddress(Date);
                    if SegHeader.Get("Segment No.") then begin
                        if SegHeader."Salesperson Code" = '' then
                            "Salesperson Code" := Cont."Salesperson Code"
                        else
                            "Salesperson Code" := SegHeader."Salesperson Code";
                        if SegHeader."Ignore Contact Corres. Type" and
                           (SegHeader."Correspondence Type (Default)" <> SegHeader."Correspondence Type (Default)"::" ")
                        then
                            "Correspondence Type" := SegHeader."Correspondence Type (Default)"
                        else
                            if InteractTmpl.Get(SegHeader."Interaction Template Code") and
                               (InteractTmpl."Ignore Contact Corres. Type" or
                                ((InteractTmpl."Ignore Contact Corres. Type" = false) and
                                 (Cont."Correspondence Type" = Cont."Correspondence Type"::" ")))
                            then
                                "Correspondence Type" := InteractTmpl."Correspondence Type (Default)"
                            else
                                "Correspondence Type" := Cont."Correspondence Type";
                    end else
                        if not Salesperson.Get(GetFilter("Salesperson Code")) then
                            "Salesperson Code" := Cont."Salesperson Code";
                end else begin
                    "Contact Company No." := '';
                    "Contact Alt. Address Code" := '';
                    if SegHeader.Get("Segment No.") then
                        "Salesperson Code" := SegHeader."Salesperson Code"
                    else begin
                        "Salesperson Code" := '';
                        "Language Code" := '';
                    end;
                end;
                CalcFields("Contact Name", "Contact Company Name");

                if "Segment No." <> '' then begin
                    if UniqueAttachmentExists then begin
                        Modify;
                        SegInteractLanguage.Reset();
                        SegInteractLanguage.SetRange("Segment No.", "Segment No.");
                        SegInteractLanguage.SetRange("Segment Line No.", "Line No.");
                        SegInteractLanguage.DeleteAll(true);
                        Get("Segment No.", "Line No.");
                    end;

                    "Language Code" := FindLanguage("Interaction Template Code", "Language Code");
                    if SegInteractLanguage.Get("Segment No.", 0, "Language Code") then begin
                        if Attachment.Get(SegInteractLanguage."Attachment No.") then
                            "Attachment No." := SegInteractLanguage."Attachment No.";
                        Subject := SegInteractLanguage.Subject;
                    end;
                end;

                if xRec."Contact No." <> "Contact No." then
                    SetCampaignTargetGroup;
            end;
        }
        field(4; "Campaign No."; Code[20])
        {
            Caption = 'Campaign No.';
            TableRelation = Campaign;

            trigger OnValidate()
            begin
                if xRec."Campaign No." <> "Campaign No." then
                    SetCampaignTargetGroup;
            end;
        }
        field(5; "Salesperson Code"; Code[20])
        {
            Caption = 'Salesperson Code';
            TableRelation = "Salesperson/Purchaser";
        }
        field(6; "Correspondence Type"; Enum "Correspondence Type")
        {
            Caption = 'Correspondence Type';

            trigger OnValidate()
            var
                Attachment: Record Attachment;
                ErrorText: Text[80];
            begin
                if not Attachment.Get("Attachment No.") then
                    exit;

                ErrorText := Attachment.CheckCorrespondenceType("Correspondence Type");
                if ErrorText <> '' then
                    Error(
                      StrSubstNo('%1%2',
                        StrSubstNo(Text000, FieldCaption("Correspondence Type"), "Correspondence Type", TableCaption, "Line No."),
                        ErrorText));
            end;
        }
        field(7; "Interaction Template Code"; Code[10])
        {
            Caption = 'Interaction Template Code';
            TableRelation = "Interaction Template";

            trigger OnValidate()
            var
                SegInteractLanguage: Record "Segment Interaction Language";
                InteractTemplLanguage: Record "Interaction Tmpl. Language";
                InteractTmpl: Record "Interaction Template";
            begin
                TestField("Contact No.");
                Cont.Get("Contact No.");
                "Attachment No." := 0;
                "Language Code" := '';
                Subject := '';
                "Correspondence Type" := "Correspondence Type"::" ";
                "Interaction Group Code" := '';
                "Cost (LCY)" := 0;
                "Duration (Min.)" := 0;
                "Information Flow" := "Information Flow"::" ";
                "Initiated By" := "Initiated By"::" ";
                "Campaign Target" := false;
                "Campaign Response" := false;
                "Correspondence Type" := "Correspondence Type"::" ";
                if (GetFilter("Campaign No.") = '') and (InteractTmpl."Campaign No." <> '') then
                    "Campaign No." := '';
                Modify;

                if "Segment No." <> '' then begin
                    SegInteractLanguage.Reset();
                    SegInteractLanguage.SetRange("Segment No.", "Segment No.");
                    SegInteractLanguage.SetRange("Segment Line No.", "Line No.");
                    SegInteractLanguage.DeleteAll(true);
                    Get("Segment No.", "Line No.");
                    if "Interaction Template Code" <> '' then begin
                        SegHeader.Get("Segment No.");
                        if "Interaction Template Code" <> SegHeader."Interaction Template Code" then begin
                            SegHeader.CreateSegInteractions("Interaction Template Code", "Segment No.", "Line No.");
                            "Language Code" := FindLanguage("Interaction Template Code", Cont."Language Code");
                            if SegInteractLanguage.Get("Segment No.", "Line No.", "Language Code") then
                                "Attachment No." := SegInteractLanguage."Attachment No.";
                        end else begin
                            "Language Code" := FindLanguage("Interaction Template Code", Cont."Language Code");
                            if SegInteractLanguage.Get("Segment No.", 0, "Language Code") then
                                "Attachment No." := SegInteractLanguage."Attachment No.";
                        end;
                    end;
                end else begin
                    "Language Code" := FindLanguage("Interaction Template Code", Cont."Language Code");
                    if InteractTemplLanguage.Get("Interaction Template Code", "Language Code") then
                        "Attachment No." := InteractTemplLanguage."Attachment No.";
                end;

                if InteractTmpl.Get("Interaction Template Code") then begin
                    "Interaction Group Code" := InteractTmpl."Interaction Group Code";
                    if Description = '' then
                        Description := InteractTmpl.Description;
                    "Cost (LCY)" := InteractTmpl."Unit Cost (LCY)";
                    "Duration (Min.)" := InteractTmpl."Unit Duration (Min.)";
                    "Information Flow" := InteractTmpl."Information Flow";
                    "Initiated By" := InteractTmpl."Initiated By";
                    "Campaign Target" := InteractTmpl."Campaign Target";
                    "Campaign Response" := InteractTmpl."Campaign Response";

                    case true of
                        SegHeader."Ignore Contact Corres. Type" and
                      (SegHeader."Correspondence Type (Default)" <> SegHeader."Correspondence Type (Default)"::" "):
                            "Correspondence Type" := SegHeader."Correspondence Type (Default)";
                        InteractTmpl."Ignore Contact Corres. Type" or
                      ((InteractTmpl."Ignore Contact Corres. Type" = false) and
                       (Cont."Correspondence Type" = Cont."Correspondence Type"::" ") and
                       (InteractTmpl."Correspondence Type (Default)" <> InteractTmpl."Correspondence Type (Default)"::" ")):
                            "Correspondence Type" := InteractTmpl."Correspondence Type (Default)";
                        else
                            if Cont."Correspondence Type" <> Cont."Correspondence Type"::" " then
                                "Correspondence Type" := Cont."Correspondence Type"
                            else
                                "Correspondence Type" := xRec."Correspondence Type";
                    end;
                    if SegHeader."Campaign No." <> '' then
                        "Campaign No." := SegHeader."Campaign No."
                    else
                        if (GetFilter("Campaign No.") = '') and (InteractTmpl."Campaign No." <> '') then
                            "Campaign No." := InteractTmpl."Campaign No.";
                end;
                if Campaign.Get("Campaign No.") then
                    "Campaign Description" := Campaign.Description;

                Modify;
            end;
        }
        field(8; "Cost (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Cost (LCY)';
            MinValue = 0;
        }
        field(9; "Duration (Min.)"; Decimal)
        {
            Caption = 'Duration (Min.)';
            DecimalPlaces = 0 : 0;
            MinValue = 0;
        }
        field(10; "Attachment No."; Integer)
        {
            Caption = 'Attachment No.';
            TableRelation = Attachment;
        }
        field(11; "Campaign Response"; Boolean)
        {
            Caption = 'Campaign Response';
        }
        field(12; "Contact Name"; Text[100])
        {
            CalcFormula = Lookup (Contact.Name WHERE("No." = FIELD("Contact No."),
                                                     Type = CONST(Person)));
            Caption = 'Contact Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(13; "Information Flow"; Option)
        {
            BlankZero = true;
            Caption = 'Information Flow';
            OptionCaption = ' ,Outbound,Inbound';
            OptionMembers = " ",Outbound,Inbound;
        }
        field(14; "Initiated By"; Option)
        {
            BlankZero = true;
            Caption = 'Initiated By';
            OptionCaption = ' ,Us,Them';
            OptionMembers = " ",Us,Them;
        }
        field(15; "Contact Alt. Address Code"; Code[10])
        {
            Caption = 'Contact Alt. Address Code';
            TableRelation = "Contact Alt. Address".Code WHERE("Contact No." = FIELD("Contact No."));
        }
        field(16; Evaluation; Option)
        {
            Caption = 'Evaluation';
            OptionCaption = ' ,Very Positive,Positive,Neutral,Negative,Very Negative';
            OptionMembers = " ","Very Positive",Positive,Neutral,Negative,"Very Negative";
        }
        field(17; "Campaign Target"; Boolean)
        {
            Caption = 'Campaign Target';

            trigger OnValidate()
            begin
                if xRec."Campaign Target" <> "Campaign Target" then
                    SetCampaignTargetGroup;
            end;
        }
        field(18; "Contact Company Name"; Text[100])
        {
            CalcFormula = Lookup (Contact.Name WHERE("No." = FIELD("Contact Company No."),
                                                     Type = CONST(Company)));
            Caption = 'Contact Company Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(19; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;

            trigger OnLookup()
            begin
                LanguageCodeOnLookup;
            end;

            trigger OnValidate()
            var
                SegInteractLanguage: Record "Segment Interaction Language";
                InteractTemplLanguage: Record "Interaction Tmpl. Language";
            begin
                TestField("Interaction Template Code");

                if "Language Code" = xRec."Language Code" then
                    exit;

                if SegHeader.Get("Segment No.") then begin
                    if not UniqueAttachmentExists then begin
                        if SegInteractLanguage.Get("Segment No.", 0, "Language Code") then begin
                            "Attachment No." := SegInteractLanguage."Attachment No.";
                            Subject := SegInteractLanguage.Subject;
                        end else begin
                            "Attachment No." := 0;
                            Subject := '';
                        end;
                    end else
                        if SegInteractLanguage.Get("Segment No.", "Line No.", "Language Code") then begin
                            "Attachment No." := SegInteractLanguage."Attachment No.";
                            Subject := SegInteractLanguage.Subject;
                        end else begin
                            "Attachment No." := 0;
                            Subject := '';
                        end;
                    Modify;
                end else begin
                    InteractTemplLanguage.Get("Interaction Template Code", "Language Code");
                    SetInteractionAttachment;
                end;
            end;
        }
        field(22; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(23; Date; Date)
        {
            Caption = 'Date';

            trigger OnValidate()
            begin
                if Cont.Get("Contact No.") then
                    if "Contact Alt. Address Code" = Cont.ActiveAltAddress(xRec.Date) then
                        "Contact Alt. Address Code" := Cont.ActiveAltAddress(Date);
            end;
        }
        field(24; "Time of Interaction"; Time)
        {
            Caption = 'Time of Interaction';
        }
        field(25; "Attempt Failed"; Boolean)
        {
            Caption = 'Attempt Failed';
        }
        field(26; "To-do No."; Code[20])
        {
            Caption = 'Task No.';
            TableRelation = "To-do";
        }
        field(27; "Contact Company No."; Code[20])
        {
            Caption = 'Contact Company No.';
            TableRelation = Contact WHERE(Type = CONST(Company));
        }
        field(28; "Campaign Entry No."; Integer)
        {
            Caption = 'Campaign Entry No.';
            Editable = false;
            TableRelation = "Campaign Entry";
        }
        field(29; "Interaction Group Code"; Code[10])
        {
            Caption = 'Interaction Group Code';
            TableRelation = "Interaction Group";
        }
        field(31; "Document Type"; Enum "Interaction Log Entry Document Type")
        {
            Caption = 'Document Type';
        }
        field(32; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(33; "Send Word Doc. As Attmt."; Boolean)
        {
            Caption = 'Send Word Doc. As Attmt.';
        }
        field(34; "Contact Via"; Text[80])
        {
            Caption = 'Contact Via';
        }
        field(35; "Version No."; Integer)
        {
            Caption = 'Version No.';
        }
        field(36; "Doc. No. Occurrence"; Integer)
        {
            Caption = 'Doc. No. Occurrence';
        }
        field(37; Subject; Text[100])
        {
            Caption = 'Subject';
        }
        field(44; "Opportunity No."; Code[20])
        {
            Caption = 'Opportunity No.';
            TableRelation = Opportunity;
        }
        field(9501; "Wizard Step"; Enum "Segment Line Wizard Step")
        {
            Caption = 'Wizard Step';
            Editable = false;
        }
        field(9502; "Wizard Contact Name"; Text[100])
        {
            Caption = 'Wizard Contact Name';
        }
        field(9503; "Opportunity Description"; Text[100])
        {
            Caption = 'Opportunity Description';
        }
        field(9504; "Campaign Description"; Text[100])
        {
            Caption = 'Campaign Description';
        }
        field(9505; "Interaction Successful"; Boolean)
        {
            Caption = 'Interaction Successful';
        }
        field(9506; "Dial Contact"; Boolean)
        {
            Caption = 'Dial Contact';
        }
        field(9507; "Mail Contact"; Boolean)
        {
            Caption = 'Mail Contact';
        }
    }

    keys
    {
        key(Key1; "Segment No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Segment No.", "Campaign No.", Date)
        {
        }
        key(Key3; "Contact No.", "Segment No.")
        {
        }
        key(Key4; "Campaign No.")
        {
        }
        key(Key5; "Campaign No.", "Contact Company No.", "Campaign Target")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        SegLine: Record "Segment Line";
        SegmentCriteriaLine: Record "Segment Criteria Line";
        SegmentHistory: Record "Segment History";
        SegInteractLanguage: Record "Segment Interaction Language";
        Task: Record "To-do";
    begin
        CampaignTargetGrMgt.DeleteSegfromTargetGr(Rec);

        SegInteractLanguage.Reset();
        SegInteractLanguage.SetRange("Segment No.", "Segment No.");
        SegInteractLanguage.SetRange("Segment Line No.", "Line No.");
        SegInteractLanguage.DeleteAll(true);
        Get("Segment No.", "Line No.");

        SegLine.SetRange("Segment No.", "Segment No.");
        SegLine.SetFilter("Line No.", '<>%1', "Line No.");
        if SegLine.IsEmpty then begin
            if SegHeader.Get("Segment No.") then
                SegHeader.CalcFields("No. of Criteria Actions");
            if SegHeader."No. of Criteria Actions" > 1 then
                if Confirm(Text006, true) then begin
                    SegmentCriteriaLine.SetRange("Segment No.", "Segment No.");
                    SegmentCriteriaLine.DeleteAll();
                    SegmentHistory.SetRange("Segment No.", "Segment No.");
                    SegmentHistory.DeleteAll();
                end;
        end;
        if "Contact No." <> '' then begin
            SegLine.SetRange("Contact No.", "Contact No.");
            if SegLine.IsEmpty then begin
                Task.SetRange("Segment No.", "Segment No.");
                Task.SetRange("Contact No.", "Contact No.");
                Task.ModifyAll("Segment No.", '');
            end;
        end;
    end;

    var
        Text000: Label '%1 = %2 can not be specified for %3 %4.\';
        Text001: Label 'Inherited';
        Text002: Label 'Unique';
        SegHeader: Record "Segment Header";
        Cont: Record Contact;
        Salesperson: Record "Salesperson/Purchaser";
        Campaign: Record Campaign;
        InteractTmpl: Record "Interaction Template";
        Attachment: Record Attachment;
        TempAttachment: Record Attachment temporary;
        InterLogEntryCommentLine: Record "Inter. Log Entry Comment Line";
        TempInterLogEntryCommentLine: Record "Inter. Log Entry Comment Line" temporary;
        AttachmentManagement: Codeunit AttachmentManagement;
        ClientTypeManagement: Codeunit "Client Type Management";
        Text005: Label 'You must fill in the %1 field.';
        Text004: Label 'The program has stopped importing the attachment at your request.';
        Text006: Label 'Your Segment is now empty.\Do you want to reset number of criteria actions?';
        CampaignTargetGrMgt: Codeunit "Campaign Target Group Mgt";
        Mail: Codeunit Mail;
        ResumedAttachmentNo: Integer;
        Text007: Label 'Do you want to finish this interaction later?';
        Text008: Label 'You must select an interaction template with an attachment.';
        Text009: Label 'You must select a contact to interact with.';
        Text013: Label 'You must fill in the phone number.';
        Text024: Label '%1 = %2 cannot be specified.', Comment = '%1=Correspondence Type';
        Text025: Label 'The email could not be sent because of the following error: %1.\Note: if you run %2 as administrator, you must run Outlook as administrator as well.', Comment = '%2 - product name';

    procedure InitLine()
    begin
        if not SegHeader.Get("Segment No.") then
            exit;

        Description := SegHeader.Description;
        "Campaign No." := SegHeader."Campaign No.";
        "Salesperson Code" := SegHeader."Salesperson Code";
        "Correspondence Type" := SegHeader."Correspondence Type (Default)";
        "Interaction Template Code" := SegHeader."Interaction Template Code";
        "Interaction Group Code" := SegHeader."Interaction Group Code";
        "Cost (LCY)" := SegHeader."Unit Cost (LCY)";
        "Duration (Min.)" := SegHeader."Unit Duration (Min.)";
        "Attachment No." := SegHeader."Attachment No.";
        Date := SegHeader.Date;
        "Campaign Target" := SegHeader."Campaign Target";
        "Information Flow" := SegHeader."Information Flow";
        "Initiated By" := SegHeader."Initiated By";
        "Campaign Response" := SegHeader."Campaign Response";
        "Send Word Doc. As Attmt." := SegHeader."Send Word Docs. as Attmt.";
        Clear(Evaluation);
        OnAfterInitLine(Rec, SegHeader);
    end;

    procedure AttachmentText(): Text[30]
    begin
        if AttachmentInherited then
            exit(Text001);

        if "Attachment No." <> 0 then
            exit(Text002);

        exit('');
    end;

    [Scope('OnPrem')]
    procedure MaintainAttachment()
    var
        Cont: Record Contact;
        SalutationFormula: Record "Salutation Formula";
    begin
        TestField("Interaction Template Code");

        Cont.Get("Contact No.");
        if SalutationFormula.Get(Cont."Salutation Code", "Language Code", 0) then;
        if SalutationFormula.Get(Cont."Salutation Code", "Language Code", 1) then;

        if "Attachment No." <> 0 then
            OpenAttachment
        else
            CreateAttachment;
    end;

    [Scope('OnPrem')]
    procedure CreateAttachment()
    var
        SegInteractLanguage: Record "Segment Interaction Language";
    begin
        if not SegInteractLanguage.Get("Segment No.", "Line No.", "Language Code") then begin
            SegInteractLanguage.Init();
            SegInteractLanguage."Segment No." := "Segment No.";
            SegInteractLanguage."Segment Line No." := "Line No.";
            SegInteractLanguage."Language Code" := "Language Code";
            SegInteractLanguage.Description := Description;
            SegInteractLanguage.Subject := Subject;
        end;

        SegInteractLanguage.CreateAttachment;
    end;

    [Scope('OnPrem')]
    procedure OpenAttachment()
    var
        Attachment: Record Attachment;
        Attachment2: Record Attachment;
        SegInteractLanguage: Record "Segment Interaction Language";
        NewAttachmentNo: Integer;
    begin
        if "Attachment No." = 0 then
            exit;

        Attachment.Get("Attachment No.");
        Attachment2 := Attachment;

        Attachment2.ShowAttachment(Rec, "Segment No." + ' ' + Description, false, true);

        if AttachmentInherited then begin
            NewAttachmentNo := Attachment2."No.";
            if (Attachment."Last Date Modified" <> Attachment2."Last Date Modified") or
               (Attachment."Last Time Modified" <> Attachment2."Last Time Modified")
            then begin
                SegInteractLanguage.Init();
                SegInteractLanguage."Segment No." := "Segment No.";
                SegInteractLanguage."Segment Line No." := "Line No.";
                SegInteractLanguage."Language Code" := "Language Code";
                SegInteractLanguage.Description := Description;
                SegInteractLanguage.Subject := Subject;
                SegInteractLanguage."Attachment No." := NewAttachmentNo;
                SegInteractLanguage.Insert(true);
                Get("Segment No.", "Line No.");
                "Attachment No." := NewAttachmentNo;
                Modify;
            end;
        end
    end;

    [Scope('OnPrem')]
    procedure ImportAttachment()
    var
        SegInteractLanguage: Record "Segment Interaction Language";
    begin
        if not SegInteractLanguage.Get("Segment No.", "Line No.", "Language Code") then begin
            SegInteractLanguage.Init();
            SegInteractLanguage."Segment No." := "Segment No.";
            SegInteractLanguage."Segment Line No." := "Line No.";
            SegInteractLanguage."Language Code" := "Language Code";
            SegInteractLanguage.Description := Description;
            SegInteractLanguage.Insert(true);
        end;
        SegInteractLanguage.ImportAttachment;
    end;

    [Scope('OnPrem')]
    procedure ExportAttachment()
    var
        SegInteractLanguage: Record "Segment Interaction Language";
    begin
        if UniqueAttachmentExists then begin
            if SegInteractLanguage.Get("Segment No.", "Line No.", "Language Code") then
                if SegInteractLanguage."Attachment No." <> 0 then
                    SegInteractLanguage.ExportAttachment;
        end else
            if SegInteractLanguage.Get("Segment No.", 0, "Language Code") then
                if SegInteractLanguage."Attachment No." <> 0 then
                    SegInteractLanguage.ExportAttachment;
    end;

    procedure RemoveAttachment()
    var
        SegInteractLanguage: Record "Segment Interaction Language";
    begin
        if SegInteractLanguage.Get("Segment No.", "Line No.", "Language Code") then begin
            SegInteractLanguage.Delete(true);
            Get("Segment No.", "Line No.");
        end;
        "Attachment No." := 0;
    end;

    procedure CreatePhoneCall()
    var
        TempSegmentLine: Record "Segment Line" temporary;
    begin
        Cont.Get("Contact No.");
        TempSegmentLine."Contact No." := Cont."No.";
        TempSegmentLine."Contact Via" := Cont."Phone No.";
        TempSegmentLine."Contact Company No." := Cont."Company No.";
        TempSegmentLine."To-do No." := "To-do No.";
        TempSegmentLine."Salesperson Code" := "Salesperson Code";
        if "Contact Alt. Address Code" <> '' then
            TempSegmentLine."Contact Alt. Address Code" := "Contact Alt. Address Code";
        if "Campaign No." <> '' then
            TempSegmentLine."Campaign No." := "Campaign No.";

        TempSegmentLine."Campaign Target" := "Campaign Target";
        TempSegmentLine."Campaign Response" := "Campaign Response";
        TempSegmentLine.SetRange("Contact No.", TempSegmentLine."Contact No.");
        TempSegmentLine.SetRange("Campaign No.", TempSegmentLine."Campaign No.");

        TempSegmentLine.StartWizard2;
    end;

    local procedure FindLanguage(InteractTmplCode: Code[10]; ContactLanguageCode: Code[10]) Language: Code[10]
    var
        SegInteractLanguage: Record "Segment Interaction Language";
        InteractTemplLanguage: Record "Interaction Tmpl. Language";
        InteractTmpl: Record "Interaction Template";
    begin
        if SegHeader.Get("Segment No.") then begin
            if not UniqueAttachmentExists and
               ("Interaction Template Code" = SegHeader."Interaction Template Code")
            then begin
                if SegInteractLanguage.Get("Segment No.", 0, ContactLanguageCode) then
                    Language := ContactLanguageCode
                else
                    Language := SegHeader."Language Code (Default)";
            end else
                if SegInteractLanguage.Get("Segment No.", "Line No.", ContactLanguageCode) then
                    Language := ContactLanguageCode
                else begin
                    InteractTmpl.Get(InteractTmplCode);
                    if SegInteractLanguage.Get("Segment No.", "Line No.", InteractTmpl."Language Code (Default)") then
                        Language := InteractTmpl."Language Code (Default)"
                    else begin
                        SegInteractLanguage.SetRange("Segment No.", "Segment No.");
                        SegInteractLanguage.SetRange("Segment Line No.", "Line No.");
                        if SegInteractLanguage.FindFirst then
                            Language := SegInteractLanguage."Language Code";
                    end;
                end;
        end else begin  // Create Interaction:
            if InteractTemplLanguage.Get(InteractTmplCode, ContactLanguageCode) then
                Language := ContactLanguageCode
            else
                if InteractTmpl.Get(InteractTmplCode) then
                    Language := InteractTmpl."Language Code (Default)";
        end;
    end;

    procedure AttachmentInherited(): Boolean
    var
        SegInteractLanguage: Record "Segment Interaction Language";
    begin
        if "Attachment No." = 0 then
            exit(false);
        if not SegHeader.Get("Segment No.") then
            exit(false);
        if "Interaction Template Code" = '' then
            exit(false);

        SegInteractLanguage.SetRange("Segment No.", "Segment No.");
        SegInteractLanguage.SetRange("Segment Line No.", "Line No.");
        SegInteractLanguage.SetRange("Language Code", "Language Code");
        SegInteractLanguage.SetRange("Attachment No.", "Attachment No.");
        if not SegInteractLanguage.IsEmpty then
            exit(false);

        SegInteractLanguage.SetRange("Segment Line No.", 0);
        exit(not SegInteractLanguage.IsEmpty);
    end;

    procedure SetInteractionAttachment()
    var
        Attachment: Record Attachment;
        InteractTemplLanguage: Record "Interaction Tmpl. Language";
    begin
        if InteractTemplLanguage.Get("Interaction Template Code", "Language Code") then begin
            if Attachment.Get(InteractTemplLanguage."Attachment No.") then
                "Attachment No." := InteractTemplLanguage."Attachment No."
            else
                "Attachment No." := 0;
        end;
        Modify;
    end;

    local procedure UniqueAttachmentExists(): Boolean
    var
        SegInteractLanguage: Record "Segment Interaction Language";
    begin
        if "Line No." <> 0 then begin
            SegInteractLanguage.SetRange("Segment No.", "Segment No.");
            SegInteractLanguage.SetRange("Segment Line No.", "Line No.");
            exit(not SegInteractLanguage.IsEmpty);
        end;
        exit(false);
    end;

    local procedure SetCampaignTargetGroup()
    begin
        if Campaign.Get(xRec."Campaign No.") then begin
            Campaign.CalcFields(Activated);
            if Campaign.Activated then
                CampaignTargetGrMgt.DeleteSegfromTargetGr(xRec);
        end;

        if Campaign.Get("Campaign No.") then begin
            Campaign.CalcFields(Activated);
            if Campaign.Activated then
                CampaignTargetGrMgt.AddSegLinetoTargetGr(Rec);
        end;
    end;

    procedure CopyFromInteractLogEntry(var InteractLogEntry: Record "Interaction Log Entry")
    begin
        "Line No." := InteractLogEntry."Entry No.";
        "Contact No." := InteractLogEntry."Contact No.";
        "Contact Company No." := InteractLogEntry."Contact Company No.";
        Date := InteractLogEntry.Date;
        Description := InteractLogEntry.Description;
        "Information Flow" := InteractLogEntry."Information Flow";
        "Initiated By" := InteractLogEntry."Initiated By";
        "Attachment No." := InteractLogEntry."Attachment No.";
        "Cost (LCY)" := InteractLogEntry."Cost (LCY)";
        "Duration (Min.)" := InteractLogEntry."Duration (Min.)";
        "Interaction Group Code" := InteractLogEntry."Interaction Group Code";
        "Interaction Template Code" := InteractLogEntry."Interaction Template Code";
        "Language Code" := InteractLogEntry."Interaction Language Code";
        Subject := InteractLogEntry.Subject;
        "Campaign No." := InteractLogEntry."Campaign No.";
        "Campaign Entry No." := InteractLogEntry."Campaign Entry No.";
        "Campaign Response" := InteractLogEntry."Campaign Response";
        "Campaign Target" := InteractLogEntry."Campaign Target";
        "Segment No." := InteractLogEntry."Segment No.";
        Evaluation := InteractLogEntry.Evaluation;
        "Time of Interaction" := InteractLogEntry."Time of Interaction";
        "Attempt Failed" := InteractLogEntry."Attempt Failed";
        "To-do No." := InteractLogEntry."To-do No.";
        "Salesperson Code" := InteractLogEntry."Salesperson Code";
        "Correspondence Type" := InteractLogEntry."Correspondence Type";
        "Contact Alt. Address Code" := InteractLogEntry."Contact Alt. Address Code";
        "Document Type" := InteractLogEntry."Document Type";
        "Document No." := InteractLogEntry."Document No.";
        "Doc. No. Occurrence" := InteractLogEntry."Doc. No. Occurrence";
        "Version No." := InteractLogEntry."Version No.";
        "Send Word Doc. As Attmt." := InteractLogEntry."Send Word Docs. as Attmt.";
        "Contact Via" := InteractLogEntry."Contact Via";
        "Opportunity No." := InteractLogEntry."Opportunity No.";

        OnAfterCopyFromInteractionLogEntry(Rec, InteractLogEntry);
    end;

    [Scope('OnPrem')]
    procedure CreateInteractionFromContact(var Contact: Record Contact)
    begin
        DeleteAll();
        Init;
        if Contact.Type = Contact.Type::Person then
            SetRange("Contact Company No.", Contact."Company No.");
        SetRange("Contact No.", Contact."No.");
        Validate("Contact No.", Contact."No.");

        "Salesperson Code" := FindSalespersonByUserEmail;
        if "Salesperson Code" = '' then
            "Salesperson Code" := Contact."Salesperson Code";

        OnCreateInteractionFromContactOnBeforeStartWizard(Rec, Contact);

        StartWizard;
    end;

    procedure CreateInteractionFromSalesperson(var Salesperson: Record "Salesperson/Purchaser")
    begin
        DeleteAll();
        Init;
        Validate("Salesperson Code", Salesperson.Code);
        SetRange("Salesperson Code", Salesperson.Code);

        OnCreateInteractionFromSalespersonOnBeforeStartWizard(Rec, Salesperson);

        StartWizard;
    end;

    procedure CreateInteractionFromInteractLogEntry(var InteractionLogEntry: Record "Interaction Log Entry")
    var
        Cont: Record Contact;
        Salesperson: Record "Salesperson/Purchaser";
        Campaign: Record Campaign;
        Task: Record "To-do";
        Opportunity: Record Opportunity;
    begin
        if Task.Get(InteractionLogEntry.GetFilter("To-do No.")) then begin
            CreateFromTask(Task);
            SetRange("To-do No.", "To-do No.");
        end else begin
            if Cont.Get(InteractionLogEntry.GetFilter("Contact Company No.")) then begin
                Validate("Contact No.", Cont."Company No.");
                SetRange("Contact No.", "Contact No.");
            end;
            if Cont.Get(InteractionLogEntry.GetFilter("Contact No.")) then begin
                Validate("Contact No.", Cont."No.");
                SetRange("Contact No.", "Contact No.");
            end;
            if Salesperson.Get(InteractionLogEntry.GetFilter("Salesperson Code")) then begin
                "Salesperson Code" := Salesperson.Code;
                SetRange("Salesperson Code", "Salesperson Code");
            end;
            if Campaign.Get(InteractionLogEntry.GetFilter("Campaign No.")) then begin
                "Campaign No." := Campaign."No.";
                SetRange("Campaign No.", "Campaign No.");
            end;
            if Opportunity.Get(InteractionLogEntry.GetFilter("Opportunity No.")) then begin
                "Opportunity No." := Opportunity."No.";
                SetRange("Opportunity No.", "Opportunity No.");
            end;
        end;

        OnCreateInteractionFromInteractLogEntryOnBeforeStartWizard(Rec, InteractionLogEntry);

        StartWizard;
    end;

    procedure CreateInteractionFromTask(var Task: Record "To-do")
    begin
        Init;
        CreateFromTask(Task);
        SetRange("To-do No.", "To-do No.");

        OnCreateInteractionFromTaskOnBeforeStartWizard(Rec, Task);

        StartWizard;
    end;

    procedure CreateInteractionFromOpp(var Opportunity: Record Opportunity)
    var
        Contact: Record Contact;
        Salesperson: Record "Salesperson/Purchaser";
        Campaign: Record Campaign;
    begin
        Init;
        if Contact.Get(Opportunity."Contact Company No.") then begin
            Contact.CheckIfPrivacyBlockedGeneric;
            Validate("Contact No.", Contact."Company No.");
            SetRange("Contact No.", "Contact No.");
        end;
        if Contact.Get(Opportunity."Contact No.") then begin
            Contact.CheckIfPrivacyBlockedGeneric;
            Validate("Contact No.", Contact."No.");
            SetRange("Contact No.", "Contact No.");
        end;
        if Salesperson.Get(Opportunity."Salesperson Code") then begin
            Validate("Salesperson Code", Salesperson.Code);
            SetRange("Salesperson Code", "Salesperson Code");
        end;
        if Campaign.Get(Opportunity."Campaign No.") then begin
            Validate("Campaign No.", Campaign."No.");
            SetRange("Campaign No.", "Campaign No.");
        end;
        Validate("Opportunity No.", Opportunity."No.");
        SetRange("Opportunity No.", "Opportunity No.");

        OnCreateInteractionFromOppOnBeforeStartWizard(Rec, Opportunity);

        StartWizard;
    end;

    procedure CreateOpportunity(): Code[20]
    var
        Opportunity: Record Opportunity;
    begin
        Opportunity.CreateFromSegmentLine(Rec);
        exit(Opportunity."No.");
    end;

    local procedure CreateFromTask(Task: Record "To-do")
    begin
        "To-do No." := Task."No.";
        Validate("Contact No.", Task."Contact No.");
        "Salesperson Code" := Task."Salesperson Code";
        "Campaign No." := Task."Campaign No.";
        "Opportunity No." := Task."Opportunity No.";

        OnAfterCreateFromTask(Rec, Task);
    end;

    local procedure GetContactName(): Text[100]
    var
        Cont: Record Contact;
    begin
        if Cont.Get("Contact No.") then
            exit(Cont.Name);
        if Cont.Get("Contact Company No.") then
            exit(Cont.Name);
    end;

    procedure StartWizard()
    var
        Opp: Record Opportunity;
        RelationshipPerformanceMgt: Codeunit "Relationship Performance Mgt.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeStartWizard(Rec, IsHandled);
        if IsHandled then
            exit;

        if Campaign.Get("Campaign No.") then
            "Campaign Description" := Campaign.Description;
        if Opp.Get("Opportunity No.") then
            "Opportunity Description" := Opp.Description;
        "Wizard Contact Name" := GetContactName;
        "Wizard Step" := "Wizard Step"::"1";
        "Interaction Successful" := true;
        Validate(Date, WorkDate);
        "Time of Interaction" := DT2Time(RoundDateTime(CurrentDateTime + 1000, 60000, '>'));
        Insert;

        if PAGE.RunModal(PAGE::"Create Interaction", Rec, "Interaction Template Code") = ACTION::OK then;
        if "Wizard Step" = "Wizard Step"::"6" then
            RelationshipPerformanceMgt.SendCreateOpportunityNotification(Rec);
    end;

    procedure CheckStatus()
    var
        InteractTmpl: Record "Interaction Template";
        Attachment: Record Attachment;
        SalutationFormula: Record "Salutation Formula";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckStatus(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Contact No." = '' then
            Error(Text009);
        if "Interaction Template Code" = '' then
            ErrorMessage(FieldCaption("Interaction Template Code"));
        if "Salesperson Code" = '' then
            ErrorMessage(FieldCaption("Salesperson Code"));
        if Date = 0D then
            ErrorMessage(FieldCaption(Date));
        if Description = '' then
            ErrorMessage(FieldCaption(Description));

        InteractTmpl.Get("Interaction Template Code");
        if InteractTmpl."Wizard Action" = InteractTmpl."Wizard Action"::Open then
            if "Attachment No." = 0 then
                ErrorMessage(Attachment.TableCaption);

        Cont.Get("Contact No.");
        if SalutationFormula.Get(Cont."Salutation Code", "Language Code", 0) then;
        if SalutationFormula.Get(Cont."Salutation Code", "Language Code", 1) then;

        if TempAttachment.FindFirst then
            TempAttachment.CalcFields("Attachment File");
        if ("Correspondence Type" = "Correspondence Type"::Email) and
           not TempAttachment."Attachment File".HasValue
        then
            Error(Text008);

        OnAfterCheckStatus(Rec);
    end;

    [Scope('OnPrem')]
    procedure FinishWizard(IsFinish: Boolean)
    var
        InteractionLogEntry: Record "Interaction Log Entry";
        SegManagement: Codeunit SegManagement;
        WordManagement: Codeunit WordManagement;
        WordApplicationHandler: Codeunit WordApplicationHandler;
        Send: Boolean;
        Flag: Boolean;
        HTMLAttachment: Boolean;
        HTMLContentBodyText: Text;
        CustomLayoutCode: Code[20];
    begin
        HTMLAttachment := IsHTMLAttachment;
        Flag := false;
        if IsFinish then
            Flag := true
        else
            Flag := Confirm(Text007);

        if Flag then begin
            CheckStatus;

            if "Opportunity No." = '' then
                "Wizard Step" := "Wizard Step"::"6";

            if not HTMLAttachment then begin
                Clear(WordManagement);
                WordManagement.Activate(WordApplicationHandler, 5077);
                HandleTrigger;
            end;

            "Attempt Failed" := not "Interaction Successful";
            Subject := Description;
            if not HTMLAttachment then
                ProcessPostponedAttachment;
            Send := (IsFinish and ("Correspondence Type" <> "Correspondence Type"::" "));
            OnFinishWizardOnAfterSetSend(Rec, Send);
            if Send and HTMLAttachment then begin
                TempAttachment.ReadHTMLCustomLayoutAttachment(HTMLContentBodyText, CustomLayoutCode);
                AttachmentManagement.GenerateHTMLContent(TempAttachment, Rec);
            end;
            SegManagement.LogInteraction(Rec, TempAttachment, TempInterLogEntryCommentLine, send, not IsFinish);
            InteractionLogEntry.FindLast;
            if Send and (InteractionLogEntry."Delivery Status" = InteractionLogEntry."Delivery Status"::Error) then begin
                if HTMLAttachment then begin
                    Clear(TempAttachment);
                    LoadTempAttachment(false);
                    TempAttachment.WriteHTMLCustomLayoutAttachment(HTMLContentBodyText, CustomLayoutCode);
                    Commit();
                end;
                if not (ClientTypeManagement.GetCurrentClientType in [CLIENTTYPE::Web, CLIENTTYPE::Tablet, CLIENTTYPE::Phone]) then
                    if Mail.GetErrorDesc <> '' then
                        Error(Text025, Mail.GetErrorDesc, PRODUCTNAME.Full);
            end;
            WordManagement.Deactivate(5077);
        end;

        OnAfterFinishWizard(Rec, InteractionLogEntry, IsFinish, Flag);
    end;

    local procedure ErrorMessage(FieldName: Text[1024])
    begin
        Error(Text005, FieldName);
    end;

    procedure ValidateCorrespondenceType()
    var
        ErrorText: Text[80];
    begin
        if "Correspondence Type" <> "Correspondence Type"::" " then
            if TempAttachment.FindFirst then begin
                ErrorText := TempAttachment.CheckCorrespondenceType("Correspondence Type");
                if ErrorText <> '' then
                    Error(
                      Text024 + ErrorText,
                      FieldCaption("Correspondence Type"), "Correspondence Type");
            end;
    end;

    local procedure HandleTrigger()
    var
        TempBlob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
        ImportedFileName: Text;
    begin
        InteractTmpl.Get("Interaction Template Code");

        case InteractTmpl."Wizard Action" of
            InteractTmpl."Wizard Action"::" ":
                if "Attachment No." <> 0 then begin
                    LoadTempAttachment(false);
                    Subject := Description;
                    TempAttachment.RunAttachment(Rec, Description, true, false, false);
                end;
            InteractTmpl."Wizard Action"::Open:
                begin
                    TestField("Attachment No.");
                    LoadTempAttachment(false);
                    Subject := Description;
                    TempAttachment.ShowAttachment(Rec, Description, true, false);
                end;
            InteractTmpl."Wizard Action"::Import:
                begin
                    ImportedFileName := FileMgt.BLOBImport(TempBlob, ImportedFileName);
                    if ImportedFileName = '' then
                        Message(Text004)
                    else begin
                        TempAttachment.DeleteAll();
                        TempAttachment.SetAttachmentFileFromBlob(TempBlob);
                        TempAttachment."File Extension" := CopyStr(FileMgt.GetExtension(ImportedFileName), 1, 250);
                        TempAttachment.Insert();
                    end;
                end;
            else
                OnHandleTriggerCaseElse(Rec, InteractTmpl);
        end;
    end;

    local procedure LoadTempAttachment(ForceReload: Boolean)
    begin
        if not ForceReload and TempAttachment."Attachment File".HasValue then
            exit;
        Attachment.Get("Attachment No.");
        Attachment.CalcFields("Attachment File");
        TempAttachment.DeleteAll();
        TempAttachment.WizEmbeddAttachment(Attachment);
        TempAttachment."No." := 0;
        TempAttachment."Read Only" := false;
        if Attachment.IsHTML then
            TempAttachment."File Extension" := Attachment."File Extension";
        TempAttachment.Insert();
    end;

    procedure LoadContentBodyTextFromCustomLayoutAttachment(): Text
    var
        ContentBodyText: Text;
        CustomLayoutCode: Code[20];
    begin
        TempAttachment.ReadHTMLCustomLayoutAttachment(ContentBodyText, CustomLayoutCode);
        exit(ContentBodyText);
    end;

    procedure UpdateContentBodyTextInCustomLayoutAttachment(NewContentBodyText: Text)
    var
        OldContentBodyText: Text;
        CustomLayoutCode: Code[20];
    begin
        TempAttachment.Find;
        TempAttachment.ReadHTMLCustomLayoutAttachment(OldContentBodyText, CustomLayoutCode);
        TempAttachment.WriteHTMLCustomLayoutAttachment(NewContentBodyText, CustomLayoutCode);
    end;

    local procedure ProcessPostponedAttachment()
    begin
        if "Attachment No." <> 0 then begin
            LoadTempAttachment(false);
            if "Line No." <> 0 then
                "Attachment No." := ResumedAttachmentNo;
        end else
            if Attachment.Get(ResumedAttachmentNo) then
                Attachment.RemoveAttachment(false);
    end;

    [Scope('OnPrem')]
    procedure LoadAttachment(ForceReload: Boolean)
    begin
        if "Line No." <> 0 then begin
            InterLogEntryCommentLine.SetRange("Entry No.", "Line No.");
            if InterLogEntryCommentLine.Find('-') then
                repeat
                    TempInterLogEntryCommentLine.Init();
                    TempInterLogEntryCommentLine.TransferFields(InterLogEntryCommentLine, false);
                    TempInterLogEntryCommentLine."Line No." := InterLogEntryCommentLine."Line No.";
                    TempInterLogEntryCommentLine.Insert();
                until InterLogEntryCommentLine.Next = 0;
            ResumedAttachmentNo := "Attachment No.";
        end;
        if "Attachment No." <> 0 then
            LoadTempAttachment(ForceReload)
        else begin
            TempAttachment.DeleteAll();
            Clear(TempAttachment);
        end;
    end;

    procedure MakePhoneCallFromContact(var Cont: Record Contact; Task: Record "To-do"; TableNo: Integer; PhoneNo: Text[30]; ContAltAddrCode: Code[10])
    begin
        Init;
        if Cont.Type = Cont.Type::Person then
            SetRange("Contact No.", Cont."No.")
        else
            SetRange("Contact Company No.", Cont."Company No.");
        if PhoneNo <> '' then
            "Contact Via" := PhoneNo
        else
            "Contact Via" := Cont."Phone No.";
        Validate("Contact No.", Cont."No.");
        "Contact Name" := Cont.Name;
        Validate(Date, Today);
        if ContAltAddrCode <> '' then
            "Contact Alt. Address Code" := ContAltAddrCode;
        if TableNo = DATABASE::"To-do" then
            "To-do No." := Task."No.";
        StartWizard2;
    end;

    procedure StartWizard2()
    var
        InteractionTmplSetup: Record "Interaction Template Setup";
        Campaign: Record Campaign;
    begin
        OnBeforeStartWizard2(Rec);

        InteractionTmplSetup.Get();
        InteractionTmplSetup.TestField("Outg. Calls");

        "Wizard Step" := "Wizard Step"::"1";
        if Date = 0D then
            Date := Today;
        "Time of Interaction" := Time;
        "Interaction Successful" := true;
        "Dial Contact" := true;

        if Campaign.Get(GetFilter("Campaign No.")) then
            "Campaign Description" := Campaign.Description;
        "Wizard Contact Name" := GetContactName;

        Insert;
        Validate("Interaction Template Code", InteractionTmplSetup."Outg. Calls");
        if PAGE.RunModal(PAGE::"Make Phone Call", Rec, "Contact Via") = ACTION::OK then;
    end;

    procedure CheckPhoneCallStatus()
    begin
        if "Wizard Step" = "Wizard Step"::"1" then begin
            if "Dial Contact" and ("Contact Via" = '') then
                Error(Text013);
            if Date = 0D then
                ErrorMessage(FieldCaption(Date));
            if Description = '' then
                ErrorMessage(FieldCaption(Description));
            if "Salesperson Code" = '' then
                ErrorMessage(FieldCaption("Salesperson Code"));
        end;
    end;

    [Scope('OnPrem')]
    procedure LogPhoneCall()
    var
        TempAttachment: Record Attachment temporary;
        SegLine: Record "Segment Line";
        SegManagement: Codeunit SegManagement;
    begin
        "Attempt Failed" := not "Interaction Successful";

        SegManagement.LogInteraction(Rec, TempAttachment, TempInterLogEntryCommentLine, false, false);

        if SegLine.Get("Segment No.", "Line No.") then begin
            SegLine.LockTable();
            SegLine."Contact Via" := "Contact Via";
            SegLine."Wizard Step" := SegLine."Wizard Step"::" ";
            SegLine.Modify();
        end;
    end;

    procedure ShowComment()
    begin
        PAGE.RunModal(PAGE::"Inter. Log Entry Comment Sheet", TempInterLogEntryCommentLine);
    end;

    procedure SetComments(var InterLogEntryCommentLine: Record "Inter. Log Entry Comment Line")
    begin
        TempInterLogEntryCommentLine.DeleteAll();

        if InterLogEntryCommentLine.FindSet then
            repeat
                TempInterLogEntryCommentLine := InterLogEntryCommentLine;
                TempInterLogEntryCommentLine.Insert();
            until InterLogEntryCommentLine.Next = 0;
    end;

    procedure IsHTMLAttachment(): Boolean
    begin
        if not TempAttachment.Find then
            exit(false);
        exit(TempAttachment.IsHTML);
    end;

    [Scope('OnPrem')]
    procedure PreviewHTMLContent()
    begin
        TempAttachment.Find;
        TempAttachment.ShowAttachment(Rec, '', true, false);
    end;

    procedure LanguageCodeOnLookup()
    var
        SegInteractLanguage: Record "Segment Interaction Language";
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
    begin
        TestField("Interaction Template Code");

        if SegHeader.Get("Segment No.") then begin
            SegInteractLanguage.SetRange("Segment No.", "Segment No.");
            if UniqueAttachmentExists or
               ("Interaction Template Code" <> SegHeader."Interaction Template Code")
            then
                SegInteractLanguage.SetRange("Segment Line No.", "Line No.")
            else
                SegInteractLanguage.SetRange("Segment Line No.", 0);

            if PAGE.RunModal(0, SegInteractLanguage) = ACTION::LookupOK then begin
                Get("Segment No.", "Line No.");
                "Language Code" := SegInteractLanguage."Language Code";
                "Attachment No." := SegInteractLanguage."Attachment No.";
                Subject := SegInteractLanguage.Subject;
                Modify;
            end else
                Get("Segment No.", "Line No.");
        end else begin  // Create Interaction
            InteractionTmplLanguage.SetRange("Interaction Template Code", "Interaction Template Code");
            if PAGE.RunModal(0, InteractionTmplLanguage) = ACTION::LookupOK then begin
                "Language Code" := InteractionTmplLanguage."Language Code";
                Modify;
            end;
            SetInteractionAttachment;
        end;
    end;

    procedure FilterContactCompanyOpportunities(var Opportunity: Record Opportunity)
    begin
        Opportunity.Reset();
        Opportunity.SetRange(Closed, false);
        if "Salesperson Code" <> '' then
            Opportunity.SetRange("Salesperson Code", "Salesperson Code");
        Opportunity.SetFilter("Contact Company No.", "Contact Company No.");
        if "Opportunity No." <> '' then begin
            Opportunity.SetRange("No.", "Opportunity No.");
            if Opportunity.FindFirst then;
            Opportunity.SetRange("No.");
        end;
    end;

    local procedure FindSalespersonByUserEmail(): Code[20]
    var
        User: Record User;
        Salesperson: Record "Salesperson/Purchaser";
        Email: Text[250];
    begin
        User.SetRange("User Name", UserId);
        if User.FindFirst then
            Email := User."Authentication Email";

        if Email <> '' then begin
            Salesperson.SetRange("E-Mail", Email);
            if Salesperson.Count = 1 then begin
                Salesperson.FindFirst;
                "Salesperson Code" := Salesperson.Code;
            end;
        end;
        exit("Salesperson Code");
    end;

    procedure ExportODataFields()
    var
        TenantWebService: Record "Tenant Web Service";
        ODataFieldsExport: Page "OData Fields Export";
        RecRef: RecordRef;
    begin
        TenantWebService.SetRange("Object Type", TenantWebService."Object Type"::Query);
        TenantWebService.SetRange("Object ID", QUERY::"Segment Lines");
        TenantWebService.FindFirst;

        RecRef.Open(DATABASE::"Segment Line");
        RecRef.SetView(GetView);

        ODataFieldsExport.SetExportData(TenantWebService, RecRef);
        ODataFieldsExport.RunModal;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckStatus(var SegmentLine: Record "Segment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromInteractionLogEntry(var SegmentLine: Record "Segment Line"; InteractionLogEntry: Record "Interaction Log Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateFromTask(var SegmentLine: Record "Segment Line"; Task: Record "To-do")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitLine(var SegmentLine: Record "Segment Line"; SegmentHeader: Record "Segment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFinishWizard(var SegmentLine: Record "Segment Line"; InteractionLogEntry: Record "Interaction Log Entry"; IsFinish: Boolean; Flag: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckStatus(var SegmentLine: Record "Segment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeStartWizard(var SegmentLine: Record "Segment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeStartWizard2(var SegmentLine: Record "Segment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateInteractionFromContactOnBeforeStartWizard(var SegmentLine: Record "Segment Line"; var Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateInteractionFromSalespersonOnBeforeStartWizard(var SegmentLine: Record "Segment Line"; SalespersonPurchaser: Record "Salesperson/Purchaser")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateInteractionFromInteractLogEntryOnBeforeStartWizard(var SegmentLine: Record "Segment Line"; InteractionLogEntry: Record "Interaction Log Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateInteractionFromTaskOnBeforeStartWizard(var SegmentLine: Record "Segment Line"; Task: Record "To-do")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateInteractionFromOppOnBeforeStartWizard(var SegmentLine: Record "Segment Line"; Opportunity: Record Opportunity)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinishWizardOnAfterSetSend(var SegmentLine: Record "Segment Line"; var Send: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHandleTriggerCaseElse(SegmentLine: Record "Segment Line"; InteractionTemplate: Record "Interaction Template")
    begin
    end;
}

