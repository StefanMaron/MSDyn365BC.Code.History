table 5104 "Segment Interaction Language"
{
    Caption = 'Segment Interaction Language';
    LookupPageID = "Segment Interaction Languages";

    fields
    {
        field(1; "Segment No."; Code[20])
        {
            Caption = 'Segment No.';
            TableRelation = "Segment Header";
        }
        field(2; "Segment Line No."; Integer)
        {
            Caption = 'Segment Line No.';
            TableRelation = "Segment Line"."Line No." WHERE("Segment No." = FIELD("Segment No."));
        }
        field(3; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        field(4; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(5; "Attachment No."; Integer)
        {
            Caption = 'Attachment No.';
        }
        field(6; Subject; Text[100])
        {
            Caption = 'Subject';

            trigger OnValidate()
            var
                SegHeader: Record "Segment Header";
                SegLine: Record "Segment Line";
                UpdateLines: Boolean;
            begin
                SegHeader.Get("Segment No.");
                if "Segment Line No." = 0 then
                    if SegHeader.SegLinesExist('') then
                        UpdateLines := Confirm(StrSubstNo(Text005, FieldCaption(Subject)), true);

                if SegHeader."Language Code (Default)" = "Language Code" then
                    if SegHeader."Subject (Default)" = xRec.Subject then begin
                        SegHeader."Subject (Default)" := Subject;
                        SegHeader.Modify();
                        Modify();
                    end;

                if not UpdateLines then
                    exit;

                SegLine.SetRange("Segment No.", "Segment No.");
                if "Segment Line No." = 0 then
                    SegLine.SetRange("Interaction Template Code", SegHeader."Interaction Template Code")
                else begin
                    SegLine.Get("Segment No.", "Segment Line No.");
                    SegLine.SetRange("Interaction Template Code", SegLine."Interaction Template Code");
                end;
                SegLine.SetRange("Language Code", "Language Code");
                SegLine.SetRange(Subject, xRec.Subject);
                SegLine.ModifyAll(Subject, Subject);
            end;
        }
        field(7; "Word Template Code"; Code[30])
        {
            DataClassification = CustomerContent;
            TableRelation = "Word Template".Code where("Table ID" = const(5106)); // Only Interaction Merge Data word templates are allowed
        }
    }

    keys
    {
        key(Key1; "Segment No.", "Segment Line No.", "Language Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        SegHeader: Record "Segment Header";
        SegLine: Record "Segment Line";
        Cont: Record Contact;
        SegInteractLanguage: Record "Segment Interaction Language";
    begin
        SegHeader.Get(Rec."Segment No.");
        if (Rec."Segment Line No." = 0) and
           (Rec."Language Code" = SegHeader."Language Code (Default)")
        then begin
            SegInteractLanguage.SetRange("Segment No.", Rec."Segment No.");
            SegInteractLanguage.SetRange("Segment Line No.", 0);
            SegInteractLanguage.SetFilter("Language Code", '<>%1', Rec."Language Code");
            if SegInteractLanguage.FindFirst() then begin
                SegHeader."Language Code (Default)" := SegInteractLanguage."Language Code";
                SegHeader."Subject (Default)" := SegInteractLanguage.Subject;
            end else begin
                SegHeader."Language Code (Default)" := '';
                SegHeader."Subject (Default)" := '';
            end;
            SegHeader.Modify();
        end;
        SegHeader.CalcFields("Attachment No.");

        if Rec."Segment Line No." = 0 then begin
            SegLine.SetRange("Segment No.", Rec."Segment No.");
            SegLine.SetRange("Attachment No.", Rec."Attachment No.");
            if SegLine.Find('-') then
                repeat
                    if Cont.Get(SegLine."Contact No.") then begin
                        if (Cont."Language Code" <> "Language Code") and
                           SegInteractLanguage.Get("Segment No.", 0, Cont."Language Code")
                        then begin
                            SegLine."Language Code" := Cont."Language Code";
                            SegLine.Subject := SegInteractLanguage.Subject;
                            SegLine."Attachment No." := SegInteractLanguage."Attachment No.";
                            SegLine."Word Template Code" := SegInteractLanguage."Word Template Code";
                        end else begin
                            SegLine."Language Code" := SegHeader."Language Code (Default)";
                            SegLine.Subject := SegHeader."Subject (Default)";
                            SegLine."Attachment No." := SegHeader."Attachment No.";
                            SegLine."Word Template Code" := SegHeader."Word Template Code";
                        end;
                        SegLine.Modify();
                    end;
                until SegLine.Next() = 0;
        end else begin // UNIQUE Attachment
            SegLine.Get("Segment No.", Rec."Segment Line No.");
            if SegLine."Attachment No." = Rec."Attachment No." then begin
                SegInteractLanguage.SetRange("Segment No.", Rec."Segment No.");
                SegInteractLanguage.SetRange("Segment Line No.", Rec."Segment Line No.");
                SegInteractLanguage.SetFilter("Language Code", '<>%1', Rec."Language Code");
                if SegInteractLanguage.FindFirst() then begin
                    SegLine."Language Code" := SegInteractLanguage."Language Code";
                    SegLine.Subject := SegInteractLanguage.Subject;
                    SegLine."Attachment No." := SegInteractLanguage."Attachment No.";
                    SegLine."Word Template Code" := SegInteractLanguage."Word Template Code";
                end else
                    if SegLine."Interaction Template Code" = SegHeader."Interaction Template Code" then begin
                        Cont.Get(SegLine."Contact No.");
                        if SegInteractLanguage.Get("Segment No.", 0, Cont."Language Code") then begin
                            SegLine."Language Code" := Cont."Language Code";
                            SegLine.Subject := SegInteractLanguage.Subject;
                            SegLine."Attachment No." := SegInteractLanguage."Attachment No.";
                            SegLine."Word Template Code" := SegInteractLanguage."Word Template Code";
                        end else begin
                            SegLine."Language Code" := SegHeader."Language Code (Default)";
                            SegLine.Subject := SegHeader."Subject (Default)";
                            SegLine."Attachment No." := SegHeader."Attachment No.";
                            SegLine."Word Template Code" := SegHeader."Word Template Code";
                        end;
                    end else begin
                        SegLine."Language Code" := '';
                        SegLine.Subject := '';
                        SegLine."Attachment No." := 0;
                        SegLine."Word Template Code" := '';
                    end;
                SegLine.Modify();
            end;
        end;

        RemoveAttachment(false);
    end;

    trigger OnInsert()
    var
        Cont: Record Contact;
        SegHeader: Record "Segment Header";
        SegLine: Record "Segment Line";
        SegInteractLanguage: Record "Segment Interaction Language";
        FirstSegIntLanguage: Boolean;
    begin
        if Rec."Segment Line No." = 0 then begin
            SegInteractLanguage.SetRange("Segment No.", Rec."Segment No.");
            SegInteractLanguage.SetRange("Segment Line No.", 0);
            FirstSegIntLanguage := not SegInteractLanguage.FindFirst();

            SegLine.SetRange("Segment No.", Rec."Segment No.");
            SegHeader.Get(Rec."Segment No.");
            SegLine.SetRange("Interaction Template Code", SegHeader."Interaction Template Code");
            if SegLine.Find('-') then
                repeat
                    if FirstSegIntLanguage then begin
                        if SegLine.AttachmentInherited() or
                           (SegLine."Attachment No." = 0)
                        then begin
                            SegLine."Language Code" := Rec."Language Code";
                            SegLine.Subject := Rec.Subject;
                            SegLine."Attachment No." := Rec."Attachment No.";
                            SegLine."Word Template Code" := Rec."Word Template Code";
                            SegLine.Modify();
                        end
                    end else
                        if SegLine.AttachmentInherited() or (SegLine."Attachment No." = 0) then
                            if Cont.Get(SegLine."Contact No.") then
                                if Cont."Language Code" = "Language Code" then begin
                                    SegLine."Language Code" := Rec."Language Code";
                                    SegLine.Subject := Rec.Subject;
                                    SegLine."Attachment No." := Rec."Attachment No.";
                                    SegLine."Word Template Code" := Rec."Word Template Code";
                                    SegLine.Modify();
                                end;
                until SegLine.Next() = 0;
        end else begin
            SegLine.Get("Segment No.", Rec."Segment Line No.");
            SegLine."Language Code" := Rec."Language Code";
            SegLine.Subject := Rec.Subject;
            SegLine."Attachment No." := Rec."Attachment No.";
            SegLine."Word Template Code" := Rec."Word Template Code";
            SegLine.Modify();
        end;
    end;

    trigger OnRename()
    var
        SegHeader: Record "Segment Header";
        SegLine: Record "Segment Line";
        Cont: Record Contact;
    begin
        SegHeader.Get("Segment No.");
        SegHeader.CalcFields("Attachment No.");
        if (Rec."Segment Line No." = 0) and
           (SegHeader."Language Code (Default)" = xRec."Language Code")
        then begin
            SegHeader."Language Code (Default)" := Rec."Language Code";
            SegHeader.Modify();
        end;

        if Rec."Segment Line No." = 0 then begin
            SegLine.SetRange("Segment No.", Rec."Segment No.");
            SegLine.SetRange("Attachment No.", Rec."Attachment No.");
            if SegLine.Find('-') then
                repeat
                    SegLine."Language Code" := SegHeader."Language Code (Default)";
                    SegLine."Attachment No." := SegHeader."Attachment No.";
                    SegLine."Word Template Code" := SegHeader."Word Template Code";
                    SegLine.Modify();
                until SegLine.Next() = 0;

            SegLine.Reset();
            SegLine.SetRange("Segment No.", Rec."Segment No.");
            SegLine.SetRange("Interaction Template Code", SegHeader."Interaction Template Code");
            if SegLine.Find('-') then
                repeat
                    if SegLine.AttachmentInherited() or (SegLine."Attachment No." = 0) then
                        if Cont.Get(SegLine."Contact No.") then
                            if Cont."Language Code" = Rec."Language Code" then begin
                                SegLine."Language Code" := Rec."Language Code";
                                SegLine.Subject := Rec.Subject;
                                SegLine."Attachment No." := Rec."Attachment No.";
                                SegLine."Word Template Code" := Rec."Word Template Code";
                                SegLine.Modify();
                            end;
                until SegLine.Next() = 0;
        end else begin
            SegLine.Get(Rec."Segment No.", Rec."Segment Line No.");
            if SegLine."Language Code" = xRec."Language Code" then begin
                SegLine."Language Code" := Rec."Language Code";
                SegLine."Attachment No." := Rec."Attachment No.";
                SegLine."Word Template Code" := Rec."Word Template Code";
                SegLine.Modify();
            end;
        end;
    end;

    var
        Text000: Label 'You have canceled the create process.';
        Text001: Label 'Replace existing attachment?';
        Text002: Label 'The import was canceled or the specified file could not be accessed. The import failed.';
        Text003: Label 'Inherited';
        Text004: Label 'Unique';
        Text005: Label 'You have modified %1.\\Do you want to update the segment lines with the same Interaction Template Code and Language Code?';

    [Scope('OnPrem')]
    procedure CreateAttachment()
    var
        SegInteractLanguage: Record "Segment Interaction Language";
        Attachment: Record Attachment;
        ClientTypeManagement: Codeunit "Client Type Management";
        NewAttachmentNo: Integer;
    begin
        if "Attachment No." <> 0 then begin
            if not Confirm(Text001, false) then
                exit;
            RemoveAttachment(false);
        end;

        if ClientTypeManagement.GetCurrentClientType() in [CLIENTTYPE::Web, CLIENTTYPE::Tablet, CLIENTTYPE::Phone, CLIENTTYPE::Desktop] then
            if Attachment.ImportAttachmentFromClientFile('', false, true) then
                NewAttachmentNo := Attachment."No.";

        if NewAttachmentNo <> 0 then begin
            "Attachment No." := NewAttachmentNo;
            if SegInteractLanguage.Get("Segment No.", "Segment Line No.", "Language Code") then
                Modify()
            else
                Insert(true);
            UpdateSegLineAttachment(0);
        end else
            Error(Text000);
    end;

    [Scope('OnPrem')]
    procedure OpenAttachment()
    var
        Attachment: Record Attachment;
    begin
        if "Attachment No." = 0 then
            exit;
        Attachment.Get("Attachment No.");
        Attachment.OpenAttachment("Segment No." + ' ' + Description, false, "Language Code");
    end;

    [Scope('OnPrem')]
    procedure CopyFromAttachment()
    var
        SegInteractLanguage: Record "Segment Interaction Language";
        AttachmentManagement: Codeunit AttachmentManagement;
        NewAttachNo: Integer;
    begin
        if "Attachment No." <> 0 then begin
            if not Confirm(Text001, false) then
                exit;
            RemoveAttachment(false);
            Commit();
        end;

        SegInteractLanguage.SetRange("Segment No.", "Segment No.");
        SegInteractLanguage.SetFilter("Attachment No.", '<>%1&<>%2', 0, "Attachment No.");
        if PAGE.RunModal(0, SegInteractLanguage) = ACTION::LookupOK then begin
            NewAttachNo := AttachmentManagement.InsertAttachment(SegInteractLanguage."Attachment No.");
            if NewAttachNo <> 0 then begin
                "Attachment No." := NewAttachNo;
                Modify();
                UpdateSegLineAttachment(0);
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure ImportAttachment()
    var
        Attachment: Record Attachment;
    begin
        if "Attachment No." <> 0 then begin
            if not Confirm(Text001, false) then
                exit;
            RemoveAttachment(false);
        end;

        if Attachment.ImportAttachmentFromClientFile('', false, false) then begin
            "Attachment No." := Attachment."No.";
            Modify();
            UpdateSegLineAttachment(0);
        end else
            Error(Text002);
    end;

    [Scope('OnPrem')]
    procedure ExportAttachment()
    var
        Attachment: Record Attachment;
        FileName: Text[1024];
    begin
        if Attachment.Get("Attachment No.") then begin
            if Attachment."Storage Type" = Attachment."Storage Type"::Embedded then
                Attachment.CalcFields("Attachment File");
            Attachment.ExportAttachmentToClientFile(FileName);
        end;
    end;

    [Scope('OnPrem')]
    procedure RemoveAttachment(Prompt: Boolean)
    var
        Attachment: Record Attachment;
        OldAttachmentNo: Integer;
    begin
        OldAttachmentNo := "Attachment No.";
        if Attachment.Get("Attachment No.") and (not Attachment."Read Only") then
            if Attachment.RemoveAttachment(Prompt) then begin
                "Attachment No." := 0;
                Modify();
            end;
        UpdateSegLineAttachment(OldAttachmentNo);
    end;

    local procedure UpdateSegLineAttachment(OldAttachmentNo: Integer)
    var
        SegLine: Record "Segment Line";
        SegHeader: Record "Segment Header";
    begin
        if "Segment Line No." = 0 then begin
            SegHeader.Get("Segment No.");
            SegLine.SetRange("Segment No.", "Segment No.");
            SegLine.SetRange("Interaction Template Code", SegHeader."Interaction Template Code");
            SegLine.SetRange("Language Code", "Language Code");
            SegLine.SetRange("Attachment No.", OldAttachmentNo);
            SegLine.ModifyAll("Attachment No.", "Attachment No.");
        end else begin
            SegLine.SetRange("Segment No.", "Segment No.");
            SegLine.SetRange("Line No.", "Segment Line No.");
            SegLine.SetRange("Attachment No.", OldAttachmentNo);
            if SegLine.FindFirst() then begin
                SegLine."Attachment No." := "Attachment No.";
                SegLine.Modify();
            end;
        end;
    end;

    procedure AttachmentText(): Text[30]
    begin
        if "Attachment No." = 0 then
            exit('');

        if "Segment Line No." = 0 then
            exit(Text003);

        exit(Text004);
    end;

    procedure Caption() CaptionText: Text
    var
        SegHeader: Record "Segment Header";
        SegLine: Record "Segment Line";
        Cont: Record Contact;
    begin
        SegHeader.Get("Segment No.");
        CaptionText := Format("Segment No.") + ' ' + SegHeader.Description;
        if "Segment Line No." <> 0 then begin
            SegLine.Get("Segment No.", "Segment Line No.");
            if Cont.Get(SegLine."Contact No.") then;
            CaptionText := CaptionText + ' ' + Format(SegLine."Contact No.") + ' ' + Cont.Name;
        end;
    end;
}

