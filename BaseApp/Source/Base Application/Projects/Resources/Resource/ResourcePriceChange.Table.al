namespace Microsoft.Projects.Resources.Resource;

using Microsoft.Finance.Currency;
using Microsoft.Utilities;

table 335 "Resource Price Change"
{
    Caption = 'Resource Price Change';
#if not CLEAN25
    DrillDownPageID = "Resource Price Changes";
    LookupPageID = "Resource Price Changes";
    ObsoleteState = Pending;
    ObsoleteTag = '16.0';
#else
    ObsoleteState = Removed;
    ObsoleteTag = '26.0';
#endif    
    ObsoleteReason = 'Replaced by the new implementation (V16) of price calculation: table Price Worksheet Line';
    DataClassification = CustomerContent;

    fields
    {
        field(2; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Resource,Group(Resource),All';
            OptionMembers = Resource,"Group(Resource)",All;
        }
        field(3; "Code"; Code[20])
        {
            Caption = 'Code';
            TableRelation = if (Type = const(Resource)) Resource
            else
            if (Type = const("Group(Resource)")) "Resource Group";

            trigger OnValidate()
            begin
                if (Code <> '') and (Type = Type::All) then
                    FieldError(Code, StrSubstNo(Text000, FieldCaption(Type), Format(Type)));
            end;
        }
        field(4; "Work Type Code"; Code[10])
        {
            Caption = 'Work Type Code';
            TableRelation = "Work Type";
        }
        field(5; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(6; "Current Unit Price"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
            Caption = 'Current Unit Price';
        }
        field(7; "New Unit Price"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
            Caption = 'New Unit Price';
        }
    }

    keys
    {
        key(Key1; Type, "Code", "Work Type Code", "Currency Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'cannot be specified when %1 is %2';
#pragma warning restore AA0470
#pragma warning restore AA0074
}

