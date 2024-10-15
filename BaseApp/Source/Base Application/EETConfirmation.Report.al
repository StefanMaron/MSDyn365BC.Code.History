report 31120 "EET Confirmation"
{
    DefaultLayout = RDLC;
    RDLCLayout = './EETConfirmation.rdlc';
    Caption = 'EET Confirmation (Obsolete)';
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
    ObsoleteTag = '18.0';

    dataset
    {
        dataitem("EET Entry"; "EET Entry")
        {
            column(EntryNo_EETEntry; "Entry No.")
            {
            }
            column(CompanyName_EETEntry; CompanyInformation.Name)
            {
            }
            column(VATRegNo_EETEntry; CompanyInformation."VAT Registration No.")
            {
            }
            column(RegNo_EETEntry; CompanyInformation."Registration No.")
            {
            }
            column(CompanyAddr1_EETEntry; CompanyAddr[1])
            {
            }
            column(CompanyAddr2_EETEntry; CompanyAddr[2])
            {
            }
            column(CompanyAddr3_EETEntry; CompanyAddr[3])
            {
            }
            column(CompanyAddr4_EETEntry; CompanyAddr[4])
            {
            }
            column(CompanyAddr5_EETEntry; CompanyAddr[5])
            {
            }
            column(SalesRegime_EETEntry; Format(EETServiceSetup."Sales Regime"))
            {
            }
            column(ReceiptSerialNo_EETEntry; "Receipt Serial No.")
            {
            }
            column(DocumentNo_EETEntry; "Document No.")
            {
            }
            column(Description_EETEntry; Description)
            {
            }
            column(TotalSalesAmount_EETEntry; "Total Sales Amount")
            {
            }
            column(SecurityCodeBKP_EETEntry; "Security Code (BKP)")
            {
            }
            column(FiscalIdentificationCode_EETEntry; "Fiscal Identification Code")
            {
            }
            column(CreationDatetime_EETEntry; "Creation Datetime")
            {
            }
            column(CashRegisterCode_EETEntry; "Cash Register Code")
            {
            }
            column(BusinessPremissesId_EETEntry; GetBusinessPremisesId)
            {
            }
            column(SalesRegimeText_EETEntry; GetSalesRegimeText)
            {
            }
            column(SignatureCodePKP_EETEntry; GetSignatureCode)
            {
            }
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
        TotalLbl = 'Total:';
        BusPremisesLbl = 'Business Premises:';
        CashRegisterLbl = 'Cash Register:';
        ReceiptSerialNoLbl = 'Receipt Serial No.:';
        BKPLbl = 'BKP:';
        FIKLbl = 'FIK:';
        PKPLbl = 'PKP:';
        IssueDatetimeLbl = 'Issue Datetime:';
        TotalSalesAmountLbl = 'Celková ƒástka trºby:';
        SalesRegimeLbl = 'EET regime:';
        VATRegNoLbl = 'VAT Reg. No.:';
        RegNoLbl = 'Reg. No.:';
        DocumentNoLbl = 'Document No.:';
        DescriptionLbl = 'Description:';
    }

    trigger OnPreReport()
    begin
        Clear(CompanyAddr);
        CompanyInformation.Get();
        FormatAddress.Company(CompanyAddr, CompanyInformation);
        EETServiceSetup.Get();
    end;

    var
        CompanyInformation: Record "Company Information";
        EETServiceSetup: Record "EET Service Setup";
        FormatAddress: Codeunit "Format Address";
        CompanyAddr: array[8] of Text[100];
}

