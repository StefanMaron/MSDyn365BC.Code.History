table 11785 "Posting Description"
{
    Caption = 'Posting Description';
    DrillDownPageID = "Posting Descriptions";
    LookupPageID = "Posting Descriptions";
    ObsoleteState = Pending;
    ObsoleteReason = 'The functionality of posting description will be removed and this table should not be used. (Obsolete::Removed in release 01.2021)';
    ObsoleteTag = '15.3';

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[30])
        {
            Caption = 'Description';
        }
        field(3; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Sales Document,Purchase Document,Post Inventory Cost,Finance Charge,Service Document';
            OptionMembers = "Sales Document","Purchase Document","Post Inventory Cost","Finance Charge","Service Document";

            trigger OnValidate()
            begin
                if (Code <> '') and (Type <> xRec.Type) then begin
                    PostDescParameter.Reset;
                    PostDescParameter.SetRange("Posting Desc. Code", Code);
                    PostDescParameter.DeleteAll;
                end;
            end;
        }
        field(4; "Posting Description Formula"; Text[50])
        {
            Caption = 'Posting Description Formula';
        }
        field(5; "Validate on Posting"; Boolean)
        {
            Caption = 'Validate on Posting';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        PostDescParameter.Reset;
        PostDescParameter.SetRange("Posting Desc. Code", Code);
        PostDescParameter.DeleteAll;
    end;

    var
        PostDescParameter: Record "Posting Desc. Parameter";

    [Scope('OnPrem')]
    [Obsolete('The functionality of posting description will be removed and this function should not be used. (Removed in release 01.2021)','15.3')]
    procedure ParsePostDescString(PostDescription: Record "Posting Description"; RecRef: RecordRef): Text[100]
    var
        "Field": Record "Field";
        FldRef: FieldRef;
        ParamNo: Integer;
        SubStrPosition: Integer;
        ParamValue: Text[100];
        ParseLine: Text[1024];
        SubStr: Text[30];
        SpcChar: Char;
    begin
        PostDescription.TestField("Posting Description Formula");
        ParseLine := PostDescription."Posting Description Formula";
        SpcChar := 1;

        for ParamNo := 1 to 9 do begin
            SubStr := '%' + Format(ParamNo);
            if PostDescParameter.Get(PostDescription.Code, ParamNo) and
               (StrPos(ParseLine, SubStr) > 0)
            then begin
                SubStrPosition := StrPos(ParseLine, SubStr);
                if PostDescParameter.Type <> PostDescParameter.Type::Constant then begin
                    FldRef := RecRef.Field(PostDescParameter."Field No.");
                    Evaluate(Field.Type, Format(FldRef.Type));
                end;
                repeat
                    ParseLine := DelStr(ParseLine, SubStrPosition, StrLen(SubStr));
                    case PostDescParameter.Type of
                        PostDescParameter.Type::Value:
                            begin
                                if Field.Type = Field.Type::Option then
                                    ParamValue := GetSelectedOption(FldRef)
                                else
                                    ParamValue := CopyStr(Format(FldRef.Value), 1, MaxStrLen(ParamValue));
                            end;
                        PostDescParameter.Type::Caption:
                            ParamValue := CopyStr(Format(FldRef.Caption), 1, MaxStrLen(ParamValue));
                        PostDescParameter.Type::Constant:
                            ParamValue := CopyStr(Format(PostDescParameter."Field Name"), 1, MaxStrLen(ParamValue));
                    end;
                    ParamValue := ConvertStr(ParamValue, '%', Format(SpcChar));
                    ParseLine := InsStr(ParseLine, ParamValue, SubStrPosition);
                    SubStrPosition := StrPos(ParseLine, SubStr);
                until (SubStrPosition = 0);
            end;
        end;
        ParseLine := ConvertStr(ParseLine, Format(SpcChar), '%');
        exit(CopyStr(ParseLine, 1, 100));
    end;

    [Scope('OnPrem')]
    [Obsolete('The functionality of posting description will be removed and this function should not be used. (Removed in release 01.2021)','15.3')]
    procedure GetSelectedOption(FldRef: FieldRef): Text[50]
    var
        SelectedOptionNo: Option;
        OptionNo: Option;
        OptionString: Text[1024];
        CurrOptionString: Text[1024];
    begin
        OptionString := FldRef.OptionCaption;
        SelectedOptionNo := FldRef.Value;
        while OptionString <> '' do begin
            if StrPos(OptionString, ',') = 0 then begin
                CurrOptionString := OptionString;
                OptionString := '';
            end else begin
                CurrOptionString := CopyStr(OptionString, 1, StrPos(OptionString, ',') - 1);
                OptionString := CopyStr(OptionString, StrPos(OptionString, ',') + 1);
            end;
            if OptionNo = SelectedOptionNo then
                exit(CopyStr(CurrOptionString, 1, 50));
            OptionNo := OptionNo + 1;
        end;
    end;
}

