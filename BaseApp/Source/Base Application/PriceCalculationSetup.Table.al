table 7006 "Price Calculation Setup"
{
    Caption = 'Price Calculation Setup';
    LookupPageID = "Price Calculation Setup";
    DrillDownPageID = "Price Calculation Setup";

    fields
    {
        field(1; Code; Code[100])
        {
            DataClassification = SystemMetadata;
        }
        field(2; Method; Enum "Price Calculation Method")
        {
            DataClassification = CustomerContent;
        }
        field(3; Type; Enum "Price Type")
        {
            DataClassification = CustomerContent;
        }
        field(4; "Asset Type"; Enum "Price Asset Type")
        {
            DataClassification = CustomerContent;
        }
        field(5; Details; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count ("Dtld. Price Calculation Setup" where("Setup Code" = field(Code)));
            Editable = false;
        }
        field(10; Implementation; Enum "Price Calculation Handler")
        {
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                AllObjWithCaption: Record AllObjWithCaption;
            begin
                AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Codeunit, Implementation.AsInteger());
            end;
        }
        field(12; Enabled; Boolean)
        {
            DataClassification = CustomerContent;
        }
        field(13; Default; Boolean)
        {
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                PriceCalculationSetup: Record "Price Calculation Setup";
            begin
                if not Default and xRec.Default then begin
                    Default := true;
                    exit; // cannot remove Default flag, pick another record to become Default
                end;

                if Default then
                    if PriceCalculationSetup.FindDefault(Method, Type) then begin
                        PriceCalculationSetup.Default := false;
                        PriceCalculationSetup.Modify();
                    end;
            end;
        }
    }
    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }
    }
    fieldgroups
    {
        fieldgroup(DropDown; Type, "Asset Type", Method, Implementation)
        {
        }
    }

    trigger OnInsert()
    begin
        DefineCode();
    end;

    local procedure DefineCode()
    begin
        Code := CopyStr(StrSubstNo('[%1]-%2', GetUID(), Implementation.AsInteger()), 1, MaxStrLen(Code));
        OnAfterDefineCode();
    end;

    procedure GetUID() UID: text;
    begin
        UID := StrSubstNo('%1-%2-%3', Method.AsInteger(), Type.AsInteger(), "Asset Type".AsInteger());
    end;

    [Scope('OnPrem')]
    procedure CopyDefaultFlagTo(var ToRec: Record "Price Calculation Setup")
    begin
        Reset();
        SetRange(Default, true);
        if FindSet() then
            repeat
                if ToRec.Get(Code) then begin
                    ToRec.Default := true;
                    ToRec.Modify();
                end;
            until Next() = 0;
    end;

    procedure FindDefault(CalculationMethod: enum "Price Calculation Method"; PriceType: Enum "Price Type"): Boolean;
    begin
        Reset();
        SetRange(Method, CalculationMethod);
        SetRange(Type, PriceType);
        SetRange(Default, true);
        exit(FindFirst());
    end;

    procedure MoveFrom(var PriceCalculationSetup: Record "Price Calculation Setup")
    begin
        Reset();
        DeleteAll();
        if PriceCalculationSetup.FindSet() then
            repeat
                Rec := PriceCalculationSetup;
                Insert();
            until PriceCalculationSetup.Next() = 0;
        PriceCalculationSetup.DeleteAll();
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterDefineCode()
    begin
    end;
}

