#if not CLEAN19
report 31010 "Sales Advance Letter List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './SalesAdvanceLetterList.rdlc';
    Caption = 'Sales Advance Letters (Obsolete)';
    UsageCategory = ReportsAndAnalysis;
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
    ObsoleteTag = '19.0';

    dataset
    {
        dataitem("Sales Advance Letter Header"; "Sales Advance Letter Header")
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
            column(Sales_Advance_Letter_Header__Template_Code_; "Template Code")
            {
            }
            column(Sales_Advance_Letter_Header__No__; "No.")
            {
            }
            column(Sales_Advance_Letter_Header__Bill_to_Customer_No__; "Bill-to Customer No.")
            {
            }
            column(Sales_Advance_Letter_Header__Bill_to_Name_; "Bill-to Name")
            {
            }
            column(Sales_Advance_Letter_Header__Posting_Description_; "Posting Description")
            {
            }
            column(Sales_Advance_Letter_Header__Currency_Code_; "Currency Code")
            {
            }
            column(Sales_Advance_Letter_Header__Amount_Including_VAT_; "Amount Including VAT")
            {
            }
            column(Sales_Advance_Letter_Header__Amount_To_Link_; "Amount To Link")
            {
            }
            column(Sales_Advance_Letter_Header__Amount_To_Invoice_; "Amount To Invoice")
            {
            }
            column(Sales_Advance_Letter_Header__Amount_To_Deduct_; "Amount To Deduct")
            {
            }
            column(Sales_Advance_Letter_Header__Document_Date_; "Document Date")
            {
            }
            column(Sales_Advance_Letter_Header__Amount_To_Deduct__Control1100171000; "Amount To Deduct")
            {
            }
            column(Sales_Advance_Letter_Header__Amount_To_Invoice__Control1100171001; "Amount To Invoice")
            {
            }
            column(Sales_Advance_Letter_Header__Amount_To_Link__Control1100171002; "Amount To Link")
            {
            }
            column(Sales_Advance_Letter_Header__Amount_Including_VAT__Control1100171003; "Amount Including VAT")
            {
            }
            column(gtcText002___FIELDCAPTION__Template_Code__; TotalForLbl + FieldCaption("Template Code"))
            {
            }
            column(Sales_Advance_Letter_Header__Amount_To_Deduct__Control1100171006; "Amount To Deduct")
            {
            }
            column(Sales_Advance_Letter_Header__Amount_To_Invoice__Control1100171007; "Amount To Invoice")
            {
            }
            column(Sales_Advance_Letter_Header__Amount_To_Link__Control1100171008; "Amount To Link")
            {
            }
            column(Sales_Advance_Letter_Header__Amount_Including_VAT__Control1100171009; "Amount Including VAT")
            {
            }
            column(gtcText001; TotalLbl)
            {
            }
            column(Sales_Advance_Letter_ListCaption; Sales_Advance_Letter_ListCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Sales_Advance_Letter_Header__No__Caption; FieldCaption("No."))
            {
            }
            column(Sales_Advance_Letter_Header__Bill_to_Customer_No__Caption; FieldCaption("Bill-to Customer No."))
            {
            }
            column(Sales_Advance_Letter_Header__Bill_to_Name_Caption; FieldCaption("Bill-to Name"))
            {
            }
            column(Sales_Advance_Letter_Header__Posting_Description_Caption; FieldCaption("Posting Description"))
            {
            }
            column(Sales_Advance_Letter_Header__Currency_Code_Caption; FieldCaption("Currency Code"))
            {
            }
            column(Sales_Advance_Letter_Header__Amount_Including_VAT_Caption; FieldCaption("Amount Including VAT"))
            {
            }
            column(Sales_Advance_Letter_Header__Amount_To_Link_Caption; FieldCaption("Amount To Link"))
            {
            }
            column(Sales_Advance_Letter_Header__Amount_To_Invoice_Caption; FieldCaption("Amount To Invoice"))
            {
            }
            column(Sales_Advance_Letter_Header__Amount_To_Deduct_Caption; FieldCaption("Amount To Deduct"))
            {
            }
            column(Sales_Advance_Letter_Header__Document_Date_Caption; FieldCaption("Document Date"))
            {
            }
            column(Sales_Advance_Letter_Header__Template_Code_Caption; FieldCaption("Template Code"))
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
        TotalLbl: Label 'Total';
        Sales_Advance_Letter_ListCaptionLbl: Label 'Sales Advance Letter List';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
}
#endif
