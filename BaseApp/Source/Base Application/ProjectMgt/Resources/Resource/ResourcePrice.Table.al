namespace Microsoft.Projects.Resources.Pricing;

using Microsoft.Finance.Currency;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Utilities;

table 201 "Resource Price"
{
    Caption = 'Resource Price';
#if not CLEAN21
    DrillDownPageID = "Resource Prices";
    LookupPageID = "Resource Prices";
    ObsoleteState = Pending;
    ObsoleteTag = '16.0';
#else
    ObsoleteState = Removed;
    ObsoleteTag = '24.0';
#endif    
    ObsoleteReason = 'Replaced by the new implementation (V16) of price calculation: table Price List Line';

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
        field(5; "Unit Price"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
            Caption = 'Unit Price';
        }
        field(6; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
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
        Text000: Label 'cannot be specified when %1 is %2';
}

