codeunit 5941 "ContractDiscount-Find"
{
    TableNo = "Contract/Service Discount";

    trigger OnRun()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
		OnBeforeFindContractDiscount(Rec, IsHandled);
		if IsHandled then
		  exit;

        ContractServDiscount.Copy(Rec);

        with ContractServDiscount do begin
            SetRange("Contract Type", "Contract Type"::Contract);
            SetRange("Contract No.", "Contract No.");
            SetRange(Type, Type);
            SetFilter("No.", '%1|%2', "No.", '');
            SetRange("Starting Date", 0D, "Starting Date");
            if not FindLast() then
                "Discount %" := 0;
        end;

        Rec := ContractServDiscount;
    end;

    var
        ContractServDiscount: Record "Contract/Service Discount";

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindContractDiscount(var ContractServiceDiscount: Record "Contract/Service Discount"; var IsHandled: Boolean);
    begin
    end;
}

