codeunit 1370 "Batch Post Parameter Types"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced by enum Batch Posting Parameter Type.';
    ObsoleteTag = '17.0';

    trigger OnRun()
    begin
    end;

    var
        Parameter: Enum "Batch Posting Parameter Type";

    procedure Invoice(): Integer
    begin
        exit(Parameter::Invoice.AsInteger());
    end;

    procedure Ship(): Integer
    begin
        exit(Parameter::Ship.AsInteger());
    end;

    procedure Receive(): Integer
    begin
        exit(Parameter::Receive.AsInteger());
    end;

    procedure Print(): Integer
    begin
        exit(Parameter::Print.AsInteger());
    end;

    procedure CalcInvoiceDiscount(): Integer
    begin
        exit(Parameter::"Calculate Invoice Discount".AsInteger());
    end;

    procedure ReplaceDocumentDate(): Integer
    begin
        exit(Parameter::"Replace Document Date".AsInteger());
    end;

    procedure ReplacePostingDate(): Integer
    begin
        exit(Parameter::"Replace Posting Date".AsInteger());
    end;

    procedure PostingDate(): Integer
    begin
        exit(Parameter::"Posting Date".AsInteger());
    end;
}

