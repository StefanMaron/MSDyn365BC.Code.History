codeunit 1370 "Batch Post Parameter Types"
{

    trigger OnRun()
    begin
    end;

    var
        Parameter: Option Invoice,Ship,Receive,"Posting Date","Replace Posting Date","Replace Document Date","Calculate Invoice Discount",Print;
        ParameterCZ: Option "VAT Date","Replace VAT Date";

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

    local procedure Offset(): Integer
    begin
        exit(10000);
    end;

    [Scope('OnPrem')]
    procedure VATDate(): Integer
    begin
        exit(Offset + ParameterCZ::"VAT Date");
    end;

    [Scope('OnPrem')]
    procedure ReplaceVATDate(): Integer
    begin
        exit(Offset + ParameterCZ::"Replace VAT Date");
    end;
}

