codeunit 1370 "Batch Post Parameter Types"
{

    trigger OnRun()
    begin
    end;

    var
        Parameter: Option Invoice,Ship,Receive,"Posting Date","Replace Posting Date","Replace Document Date","Calculate Invoice Discount",Print;

    procedure Invoice(): Integer
    begin
        exit(Parameter::Invoice);
    end;

    procedure Ship(): Integer
    begin
        exit(Parameter::Ship);
    end;

    procedure Receive(): Integer
    begin
        exit(Parameter::Receive);
    end;

    procedure Print(): Integer
    begin
        exit(Parameter::Print);
    end;

    procedure CalcInvoiceDiscount(): Integer
    begin
        exit(Parameter::"Calculate Invoice Discount");
    end;

    procedure ReplaceDocumentDate(): Integer
    begin
        exit(Parameter::"Replace Document Date");
    end;

    procedure ReplacePostingDate(): Integer
    begin
        exit(Parameter::"Replace Posting Date");
    end;

    procedure PostingDate(): Integer
    begin
        exit(Parameter::"Posting Date");
    end;
}

