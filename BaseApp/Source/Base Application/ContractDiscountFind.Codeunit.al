codeunit 5941 "ContractDiscount-Find"
{
    TableNo = "Contract/Service Discount";

    trigger OnRun()
    begin
        ContractServDiscount.Copy(Rec);

        with ContractServDiscount do begin
            SetRange("Contract Type", "Contract Type"::Contract);
            SetRange("Contract No.", "Contract No.");
            SetRange(Type, Type);
            SetFilter("No.", '%1|%2', "No.", '');
            SetRange("Starting Date", 0D, "Starting Date");
            if not FindLast then
                "Discount %" := 0;
        end;

        Rec := ContractServDiscount;
    end;

    var
        ContractServDiscount: Record "Contract/Service Discount";
}

