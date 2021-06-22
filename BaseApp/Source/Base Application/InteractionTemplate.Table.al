table 5064 "Interaction Template"
{
    Caption = 'Interaction Template';
    LookupPageID = "Interaction Templates";
    ReplicateData = true;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; "Interaction Group Code"; Code[10])
        {
            Caption = 'Interaction Group Code';
            NotBlank = true;
            TableRelation = "Interaction Group";
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(4; "Unit Cost (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Unit Cost (LCY)';
            MinValue = 0;
        }
        field(5; "Unit Duration (Min.)"; Decimal)
        {
            Caption = 'Unit Duration (Min.)';
            DecimalPlaces = 0 : 0;
            MinValue = 0;
        }
        field(6; "Information Flow"; Option)
        {
            Caption = 'Information Flow';
            OptionCaption = ' ,Outbound,Inbound';
            OptionMembers = " ",Outbound,Inbound;
        }
        field(7; "Initiated By"; Option)
        {
            Caption = 'Initiated By';
            OptionCaption = ' ,Us,Them';
            OptionMembers = " ",Us,Them;
        }
        field(8; "Attachment No."; Integer)
        {
            CalcFormula = Lookup ("Interaction Tmpl. Language"."Attachment No." WHERE("Interaction Template Code" = FIELD(Code),
                                                                                      "Language Code" = FIELD("Language Code (Default)")));
            Caption = 'Attachment No.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(9; "Campaign No."; Code[20])
        {
            Caption = 'Campaign No.';
            TableRelation = Campaign;
        }
        field(10; "Campaign Target"; Boolean)
        {
            Caption = 'Campaign Target';
        }
        field(11; "Campaign Response"; Boolean)
        {
            Caption = 'Campaign Response';
        }
        field(12; "Correspondence Type (Default)"; Enum "Correspondence Type")
        {
            Caption = 'Correspondence Type (Default)';

            trigger OnValidate()
            var
                Attachment: Record Attachment;
                ErrorText: Text[80];
            begin
                if not Attachment.Get("Attachment No.") then
                    exit;

                ErrorText := Attachment.CheckCorrespondenceType("Correspondence Type (Default)");
                if ErrorText <> '' then
                    Error(
                      StrSubstNo('%1%2',
                        StrSubstNo(Text003,
                          FieldCaption("Correspondence Type (Default)"),
                          "Correspondence Type (Default)",
                          TableCaption,
                          Code),
                        ErrorText));
            end;
        }
        field(13; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(14; "No. of Interactions"; Integer)
        {
            CalcFormula = Count ("Interaction Log Entry" WHERE("Interaction Template Code" = FIELD(Code),
                                                               Canceled = CONST(false),
                                                               Date = FIELD("Date Filter"),
                                                               Postponed = CONST(false)));
            Caption = 'No. of Interactions';
            Editable = false;
            FieldClass = FlowField;
        }
        field(15; "Cost (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("Interaction Log Entry"."Cost (LCY)" WHERE("Interaction Template Code" = FIELD(Code),
                                                                          Canceled = CONST(false),
                                                                          Date = FIELD("Date Filter"),
                                                                          Postponed = CONST(false)));
            Caption = 'Cost (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(16; "Duration (Min.)"; Decimal)
        {
            CalcFormula = Sum ("Interaction Log Entry"."Duration (Min.)" WHERE("Interaction Template Code" = FIELD(Code),
                                                                               Canceled = CONST(false),
                                                                               Date = FIELD("Date Filter"),
                                                                               Postponed = CONST(false)));
            Caption = 'Duration (Min.)';
            DecimalPlaces = 0 : 0;
            Editable = false;
            FieldClass = FlowField;
        }
        field(17; "Language Code (Default)"; Code[10])
        {
            Caption = 'Language Code (Default)';
            TableRelation = "Interaction Tmpl. Language"."Language Code" WHERE("Interaction Template Code" = FIELD(Code));

            trigger OnValidate()
            var
                InteractTmplLanguage: Record "Interaction Tmpl. Language";
            begin
                if not InteractTmplLanguage.Get(Code, "Language Code (Default)") then begin
                    if Confirm(Text004, true, InteractTmplLanguage.TableCaption, "Language Code (Default)") then begin
                        InteractTmplLanguage.Init();
                        InteractTmplLanguage."Interaction Template Code" := Code;
                        InteractTmplLanguage."Language Code" := "Language Code (Default)";
                        InteractTmplLanguage.Description := Description;
                        InteractTmplLanguage.Insert();
                    end else
                        Error('');
                end;

                if InteractTmplLanguage."Custom Layout Code" <> '' then
                    "Wizard Action" := "Wizard Action"::Merge
                else
                    if "Wizard Action" = "Wizard Action"::Merge then
                        "Wizard Action" := "Wizard Action"::" ";

                CalcFields("Attachment No.");
            end;
        }
        field(18; "Wizard Action"; Enum "Interaction Template Wizard Action")
        {
            Caption = 'Wizard Action';

            trigger OnValidate()
            var
                InteractionTmplLanguage: Record "Interaction Tmpl. Language";
            begin
                if InteractionTmplLanguage.Get(Code, "Language Code (Default)") then
                    if (InteractionTmplLanguage."Custom Layout Code" <> '') and ("Wizard Action" <> "Wizard Action"::Merge) or
                       (InteractionTmplLanguage."Custom Layout Code" = '') and ("Wizard Action" = "Wizard Action"::Merge)
                    then
                        Error(Text003, FieldCaption("Wizard Action"), "Wizard Action", TableCaption, Code);
            end;
        }
        field(19; "Ignore Contact Corres. Type"; Boolean)
        {
            Caption = 'Ignore Contact Corres. Type';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
        key(Key2; "Interaction Group Code")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Description, "Information Flow", "Attachment No.")
        {
        }
    }

    trigger OnDelete()
    var
        InteractTmplLanguage: Record "Interaction Tmpl. Language";
    begin
        InteractTmplLanguage.SetRange("Interaction Template Code", Code);
        InteractTmplLanguage.DeleteAll(true);
    end;

    var
        Text003: Label '%1 = %2 can not be specified for %3 %4.', Comment = '%1 = Wizard Action caption, %2= Wizard Action, %3 = Interaction Template, %4 = Code ';
        Text004: Label 'Do you want to create %1 %2?';
}

