report 31030 "Purch. Advance Letter List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './PurchAdvanceLetterList.rdlc';
    Caption = 'Purchase Advance Letters';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Purch. Advance Letter Header"; "Purch. Advance Letter Header")
        {
            DataItemTableView = SORTING("Template Code");
            RequestFilterFields = "Template Code", Status;
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName)
            {
            }
            column(USERID; UserId)
            {
            }
            column(Purch__Advance_Letter_Header__Template_Code_; "Template Code")
            {
            }
            column(Purch__Advance_Letter_Header__No__; "No.")
            {
            }
            column(Purch__Advance_Letter_Header__Purch__Advance_Letter_Header___Pay_to_Vendor_No__; "Pay-to Vendor No.")
            {
            }
            column(Purch__Advance_Letter_Header__Purch__Advance_Letter_Header___Pay_to_Name_; "Pay-to Name")
            {
            }
            column(Purch__Advance_Letter_Header__Posting_Description_; "Posting Description")
            {
            }
            column(Purch__Advance_Letter_Header__Currency_Code_; "Currency Code")
            {
            }
            column(Purch__Advance_Letter_Header__Amount_Including_VAT_; "Amount Including VAT")
            {
            }
            column(Purch__Advance_Letter_Header__Amount_To_Link_; "Amount To Link")
            {
            }
            column(Purch__Advance_Letter_Header__Amount_To_Invoice_; "Amount To Invoice")
            {
            }
            column(Purch__Advance_Letter_Header__Amount_To_Deduct_; "Amount To Deduct")
            {
            }
            column(Purch__Advance_Letter_Header__Document_Date_; "Document Date")
            {
            }
            column(Purch__Advance_Letter_Header__Amount_To_Deduct__Control1100171000; "Amount To Deduct")
            {
            }
            column(Purch__Advance_Letter_Header__Amount_To_Invoice__Control1100171001; "Amount To Invoice")
            {
            }
            column(Purch__Advance_Letter_Header__Amount_To_Link__Control1100171002; "Amount To Link")
            {
            }
            column(Purch__Advance_Letter_Header__Amount_Including_VAT__Control1100171003; "Amount Including VAT")
            {
            }
            column(TotalFor___FIELDCAPTION__Template_Code__; TotalForLbl + FieldCaption("Template Code"))
            {
            }
            column(Purch__Advance_Letter_Header__Amount_To_Deduct__Control1100171006; "Amount To Deduct")
            {
            }
            column(Purch__Advance_Letter_Header__Amount_To_Invoice__Control1100171007; "Amount To Invoice")
            {
            }
            column(Purch__Advance_Letter_Header__Amount_To_Link__Control1100171008; "Amount To Link")
            {
            }
            column(Purch__Advance_Letter_Header__Amount_Including_VAT__Control1100171009; "Amount Including VAT")
            {
            }
            column(gtcText001; TotlaLbl)
            {
            }
            column(Purchase_Advance_Letter_ListCaption; Purch_Advance_Letter_ListCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Purch__Advance_Letter_Header__No__Caption; FieldCaption("No."))
            {
            }
            column(Purch__Advance_Letter_Header__Purch__Advance_Letter_Header___Pay_to_Vendor_No__Caption; FieldCaption("Pay-to Vendor No."))
            {
            }
            column(Purch__Advance_Letter_Header__Purch__Advance_Letter_Header___Pay_to_Name_Caption; FieldCaption("Pay-to Name"))
            {
            }
            column(Purch__Advance_Letter_Header__Posting_Description_Caption; FieldCaption("Posting Description"))
            {
            }
            column(Purch__Advance_Letter_Header__Currency_Code_Caption; FieldCaption("Currency Code"))
            {
            }
            column(Purch__Advance_Letter_Header__Amount_Including_VAT_Caption; FieldCaption("Amount Including VAT"))
            {
            }
            column(Purch__Advance_Letter_Header__Amount_To_Link_Caption; FieldCaption("Amount To Link"))
            {
            }
            column(Purch__Advance_Letter_Header__Amount_To_Invoice_Caption; FieldCaption("Amount To Invoice"))
            {
            }
            column(Purch__Advance_Letter_Header__Amount_To_Deduct_Caption; FieldCaption("Amount To Deduct"))
            {
            }
            column(Purch__Advance_Letter_Header__Document_Date_Caption; FieldCaption("Document Date"))
            {
            }
            column(Purch__Advance_Letter_Header__Template_Code_Caption; FieldCaption("Template Code"))
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
    }

    var
        TotalForLbl: Label 'Total per';
        TotlaLbl: Label 'Total';
        Purch_Advance_Letter_ListCaptionLbl: Label 'Purchase Advance Letter List';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
}

