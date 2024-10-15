page 35493 "INAIL Contribution List"
{
    Caption = 'Contribution List';
    CardPageID = "Contribution Card";
    Editable = false;
    PageType = List;
    SourceTable = Contributions;
    SourceTableView = SORTING("INAIL Code", "Vendor No.")
                      WHERE("INAIL Code" = FILTER(<> ''));

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Month; Month)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the month of the contribution entry in numeric format.';
                }
                field(Year; Year)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the year of the contribution entry in numeric format. ';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the contribution entry is posted.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transaction date of the source document that generated the contribution entry.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a unique identification number that refers to the source document that generated the contribution entry.';
                }
                field("External Document No."; "External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an identification number that links the vendor''s source document to the contribution entry.';
                }
                field("Vendor No."; "Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the unique identification number of the vendor who is related to the contribution entry.';
                }
                field("Related Date"; "Related Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transaction date of the purchase that generated the contribution entry.';
                }
                field("Payment Date"; "Payment Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date that the contribution amount was paid to the tax authority.';
                }
                field("Social Security Code"; "Social Security Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Social Security code that is applied to this purchase.';
                    Visible = "Social Security CodeVisible";
                }
                field("INAIL Code"; "INAIL Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the INAIL withholding tax code that is applied to this purchase for workers compensation insurance.';
                    Visible = "INAIL CodeVisible";
                }
                field("Gross Amount"; "Gross Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount of the original purchase that is subject to Social Security withholding tax.';
                }
                field("INAIL Gross Amount"; "INAIL Gross Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount of the original purchase that is subject to INAIL withholding tax.';
                }
                field("Non Taxable Amount"; "Non Taxable Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the amount of the original purchase that is excluded from Social Security tax liability based on provisions in the law.';
                    Visible = "Non Taxable AmountVisible";
                }
                field("INAIL Non Taxable Amount"; "INAIL Non Taxable Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the amount of the original purchase that is excluded from the INAIL withholding tax based on provisions in the law.';
                    Visible = INAILNonTaxableAmountVisible;
                }
                field("Contribution Base"; "Contribution Base")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the amount of the original purchase that is subject to Social Security tax, after the nontaxable amount has been subtracted.';
                    Visible = "Contribution BaseVisible";
                }
                field("INAIL Contribution Base"; "INAIL Contribution Base")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the amount of the original purchase that is subject to INAIL withholding tax after non-taxable amounts have been subtracted.';
                    Visible = "INAIL Contribution BaseVisible";
                }
                field("Social Security %"; "Social Security %")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the percentage of the purchase that is subject to Social Security tax.';
                    Visible = "Social Security %Visible";
                }
                field("INAIL Per Mil"; "INAIL Per Mil")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the percentage of the purchase that is subject to the INAIL withholding tax for workers compensation insurance.';
                    Visible = "INAIL Per Mil Visible";
                }
                field("Free-Lance Amount %"; "Free-Lance Amount %")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the percentage of the Social Security tax liability that is the responsibility of the independent contractor or vendor.';
                    Visible = "Free-Lance Amount %Visible";
                }
                field("INAIL Free-Lance %"; "INAIL Free-Lance %")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the percentage of the INAIL tax liability that is the responsibility of the independent contractor or vendor.';
                    Visible = "INAIL Free-Lance %Visible";
                }
                field("Total Social Security Amount"; "Total Social Security Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total amount of Social Security tax that is due for the purchase.';
                    Visible = TotalSocialSecurityAmountVisib;
                }
                field("INAIL Total Amount"; "INAIL Total Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total amount of the INAIL withholding tax that is due for this purchase.';
                    Visible = "INAIL Total AmountVisible";
                }
                field("Free-Lance Amount"; "Free-Lance Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the amount of the Social Security tax liability that is the responsibility of the independent contractor or vendor.';
                    Visible = "Free-Lance AmountVisible";
                }
                field("INAIL Free-Lance Amount"; "INAIL Free-Lance Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the amount of the INAIL tax liability that is the responsibility of the independent contractor or vendor.';
                    Visible = "INAIL Free-Lance AmountVisible";
                }
                field("INAIL Company Amount"; "INAIL Company Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Italian Workers'' Compensation Authority (INAIL) tax amount that your company is liable for.';
                    Visible = "INAIL Company AmountVisible";
                }
                field("Company Amount"; "Company Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the amount of Social Security tax from the purchase that your company is liable for.';
                    Visible = "Company AmountVisible";
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Social Security")
            {
                Caption = '&Social Security';
                Image = SocialSecurity;
                action(Card)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "Contribution List";
                    ToolTip = 'Open the card.';
                }
            }
        }
        area(processing)
        {
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'View the number and type of entries that have the same document number or posting date.';

                trigger OnAction()
                begin
                    Navigate;
                end;
            }
        }
    }

    trigger OnInit()
    begin
        "INAIL Company AmountVisible" := true;
        "Company AmountVisible" := true;
        "Free-Lance AmountVisible" := true;
        "INAIL Free-Lance AmountVisible" := true;
        "INAIL Free-Lance %Visible" := true;
        "Free-Lance Amount %Visible" := true;
        TotalSocialSecurityAmountVisib := true;
        "INAIL Total AmountVisible" := true;
        "INAIL Per Mil Visible" := true;
        "Social Security %Visible" := true;
        "INAIL Contribution BaseVisible" := true;
        "Contribution BaseVisible" := true;
        INAILNonTaxableAmountVisible := true;
        "Non Taxable AmountVisible" := true;
        "Social Security CodeVisible" := true;
        "INAIL CodeVisible" := true;
    end;

    trigger OnOpenPage()
    begin
        if GetFilter("Social Security Code") <> '' then begin
            "INAIL CodeVisible" := false;
            "Social Security CodeVisible" := true;
            "Non Taxable AmountVisible" := true;
            INAILNonTaxableAmountVisible := false;
            "Contribution BaseVisible" := true;
            "INAIL Contribution BaseVisible" := false;
            "Social Security %Visible" := true;
            "INAIL Per Mil Visible" := false;
            "INAIL Total AmountVisible" := false;
            TotalSocialSecurityAmountVisib := true;
            "Free-Lance Amount %Visible" := true;
            "INAIL Free-Lance %Visible" := false;
            "INAIL Free-Lance AmountVisible" := false;
            "Free-Lance AmountVisible" := true;
            "Company AmountVisible" := true;
            "INAIL Company AmountVisible" := false;
        end;

        if GetFilter("INAIL Code") <> '' then begin
            "Social Security CodeVisible" := false;
            "INAIL CodeVisible" := true;
            "Non Taxable AmountVisible" := false;
            INAILNonTaxableAmountVisible := true;
            "Contribution BaseVisible" := false;
            "INAIL Contribution BaseVisible" := true;
            "Social Security %Visible" := false;
            "INAIL Per Mil Visible" := true;
            "INAIL Total AmountVisible" := true;
            TotalSocialSecurityAmountVisib := false;
            "Free-Lance Amount %Visible" := false;
            "INAIL Free-Lance %Visible" := true;
            "INAIL Free-Lance AmountVisible" := true;
            "Free-Lance AmountVisible" := false;
            "Company AmountVisible" := false;
            "INAIL Company AmountVisible" := true;
        end;
    end;

    var
        [InDataSet]
        "INAIL CodeVisible": Boolean;
        [InDataSet]
        "Social Security CodeVisible": Boolean;
        [InDataSet]
        "Non Taxable AmountVisible": Boolean;
        [InDataSet]
        INAILNonTaxableAmountVisible: Boolean;
        [InDataSet]
        "Contribution BaseVisible": Boolean;
        [InDataSet]
        "INAIL Contribution BaseVisible": Boolean;
        [InDataSet]
        "Social Security %Visible": Boolean;
        [InDataSet]
        "INAIL Per Mil Visible": Boolean;
        [InDataSet]
        "INAIL Total AmountVisible": Boolean;
        [InDataSet]
        TotalSocialSecurityAmountVisib: Boolean;
        [InDataSet]
        "Free-Lance Amount %Visible": Boolean;
        [InDataSet]
        "INAIL Free-Lance %Visible": Boolean;
        [InDataSet]
        "INAIL Free-Lance AmountVisible": Boolean;
        [InDataSet]
        "Free-Lance AmountVisible": Boolean;
        [InDataSet]
        "Company AmountVisible": Boolean;
        [InDataSet]
        "INAIL Company AmountVisible": Boolean;
}

