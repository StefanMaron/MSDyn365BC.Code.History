namespace Microsoft.Foundation.AuditCodes;

using Microsoft.Service.Contract;

#pragma warning disable AS0125
tableextension 6469 "Serv. Reason Code" extends "Reason Code"
{
    fields
    {
        field(5900; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
        }
        field(5901; "Contract Gain/Loss Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Contract Gain/Loss Entry".Amount where("Reason Code" = field(Code),
                                                                       "Change Date" = field("Date Filter")));
            Caption = 'Contract Gain/Loss Amount';
            Editable = false;
            FieldClass = FlowField;
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
        }
    }

    fieldgroups
    {
        addlast(Brick; "Date Filter")
        {
        }
    }
}
#pragma warning restore AS0125        
