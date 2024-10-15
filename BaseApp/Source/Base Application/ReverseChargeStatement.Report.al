report 31085 "Reverse Charge Statement"
{
    DefaultLayout = RDLC;
    RDLCLayout = './ReverseChargeStatement.rdlc';
    Caption = 'Reverse Charge Statement';

    dataset
    {
        dataitem("Reverse Charge Header"; "Reverse Charge Header")
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.";
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName)
            {
            }
            column(PeriodNo_ReverseChargeHeader; "Period No.")
            {
                IncludeCaption = true;
            }
            column(Year_ReverseChargeHeader; Year)
            {
                IncludeCaption = true;
            }
            column(DeclarationPeriod_ReverseChargeHeader; "Declaration Period")
            {
                IncludeCaption = true;
            }
            column(StatementType_ReverseChargeHeader; "Statement Type")
            {
                IncludeCaption = true;
            }
            dataitem("Reverse Charge Line"; "Reverse Charge Line")
            {
                DataItemLink = "Reverse Charge No." = FIELD("No.");
                DataItemTableView = SORTING("Reverse Charge No.", "Line No.");
                column(DocumentNo_ReverseChargeLine; "Document No.")
                {
                    IncludeCaption = true;
                }
                column(VATRegistrationNo_ReverseChargeLine; "VAT Registration No.")
                {
                    IncludeCaption = true;
                }
                column(CommodityCode_ReverseChargeLine; "Commodity Code")
                {
                    IncludeCaption = true;
                }
                column(Quantity_ReverseChargeLine; Quantity)
                {
                    IncludeCaption = true;
                }
                column(UnitofMeasureCode_ReverseChargeLine; "Unit of Measure Code")
                {
                    IncludeCaption = true;
                }
                column(VATBaseAmountLCY_ReverseChargeLine; "VAT Base Amount (LCY)")
                {
                    IncludeCaption = true;
                }
                column(VATDate_ReverseChargeLine; "VAT Date")
                {
                    IncludeCaption = true;
                }
                column(DocumentQuantity_ReverseChargeLine; "Document Quantity")
                {
                    IncludeCaption = true;
                }
                column(DocumentUnitofMeasureCode_ReverseChargeLine; "Document Unit of Measure Code")
                {
                    IncludeCaption = true;
                }
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
        DocumentLbl = 'Reverse Charge Statement';
        PageLbl = 'Page';
        TotalLbl = 'Total';
    }
}

