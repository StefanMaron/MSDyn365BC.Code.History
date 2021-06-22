codeunit 8622 "Config. Insert With Validation"
{

    trigger OnRun()
    begin
        InsertWithValidation;
    end;

    var
        RecRefToInsert: RecordRef;

    procedure SetInsertParameters(var RecRef: RecordRef)
    begin
        RecRefToInsert := RecRef;
    end;

    local procedure InsertWithValidation()
    begin
        RecRefToInsert.Insert(true);
    end;
}

