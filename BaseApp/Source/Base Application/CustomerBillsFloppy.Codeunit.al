codeunit 12176 "Customer Bills Floppy"
{
    TableNo = "Direct Debit Collection Entry";

    trigger OnRun()
    var
        CustomerBillHeader: Record "Customer Bill Header";
        IssuedCustomerBillHeader: Record "Issued Customer Bill Header";
        DirectDebitCollection: Record "Direct Debit Collection";
        SEPADDExportMgt: Codeunit "SEPA - DD Export Mgt.";
    begin
        DirectDebitCollection.Get(GetRangeMin("Direct Debit Collection No."));
        case DirectDebitCollection."Source Table ID" of
            DATABASE::"Customer Bill Header":
                begin
                    CustomerBillHeader.SetRange("No.", DirectDebitCollection.Identifier);
                    CustomerBillHeader.FindFirst;
                    SEPADDExportMgt.CheckBillHeader(CustomerBillHeader."Payment Method Code");
                    REPORT.Run(REPORT::"Cust Bills Floppy", false, false, CustomerBillHeader);
                end;
            DATABASE::"Issued Customer Bill Header":
                begin
                    IssuedCustomerBillHeader.SetRange("No.", DirectDebitCollection.Identifier);
                    IssuedCustomerBillHeader.FindFirst;
                    SEPADDExportMgt.CheckBillHeader(IssuedCustomerBillHeader."Payment Method Code");
                    REPORT.Run(REPORT::"Issued Cust Bills Floppy", false, false, IssuedCustomerBillHeader);
                end;
        end;
    end;
}

