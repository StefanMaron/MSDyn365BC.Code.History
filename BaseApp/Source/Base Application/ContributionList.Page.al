page 12115 "Contribution List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Social Security';
    CardPageID = "Contribution Card";
    Editable = false;
    PageType = List;
    SourceTable = Contributions;
    UsageCategory = Lists;

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
                    Visible = SocialSecurityCodeVisible;
                }
                field("INAIL Code"; "INAIL Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the INAIL withholding tax code that is applied to this purchase for workers compensation insurance.';
                    Visible = INAILCodeVisible;
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
                    Visible = NonTaxableAmountVisible;
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
                    Visible = ContributionBaseVisible;
                }
                field("INAIL Contribution Base"; "INAIL Contribution Base")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the amount of the original purchase that is subject to INAIL withholding tax after non-taxable amounts have been subtracted.';
                    Visible = INAILContributionBaseVisible;
                }
                field("Social Security %"; "Social Security %")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the percentage of the purchase that is subject to Social Security tax.';
                    Visible = SocialSecurityPctVisible;
                }
                field("INAIL Per Mil"; "INAIL Per Mil")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the percentage of the purchase that is subject to the INAIL withholding tax for workers compensation insurance.';
                    Visible = INAILPerMilVisible;
                }
                field("Free-Lance Amount %"; "Free-Lance Amount %")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the percentage of the Social Security tax liability that is the responsibility of the independent contractor or vendor.';
                    Visible = FreeLanceAmountPctVisible;
                }
                field("INAIL Free-Lance %"; "INAIL Free-Lance %")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the percentage of the INAIL tax liability that is the responsibility of the independent contractor or vendor.';
                    Visible = INAILFreeLancePctVisible;
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
                    Visible = INAILTotalAmountVisible;
                }
                field("Free-Lance Amount"; "Free-Lance Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the amount of the Social Security tax liability that is the responsibility of the independent contractor or vendor.';
                    Visible = FreeLanceAmountVisible;
                }
                field("INAIL Free-Lance Amount"; "INAIL Free-Lance Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the amount of the INAIL tax liability that is the responsibility of the independent contractor or vendor.';
                    Visible = INAILFreeLanceAmountVisible;
                }
                field("INAIL Company Amount"; "INAIL Company Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Italian Workers'' Compensation Authority (INAIL) tax amount that your company is liable for.';
                    Visible = INAILCompanyAmountVisible;
                }
                field("Company Amount"; "Company Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the amount of Social Security tax from the purchase that your company is liable for.';
                    Visible = CompanyAmountVisible;
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
            action(Navigate)
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Navigate';
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
        INAILCompanyAmountVisible := true;
        CompanyAmountVisible := true;
        FreeLanceAmountVisible := true;
        INAILFreeLanceAmountVisible := true;
        INAILFreeLancePctVisible := true;
        FreeLanceAmountPctVisible := true;
        TotalSocialSecurityAmountVisib := true;
        INAILTotalAmountVisible := true;
        INAILPerMilVisible := true;
        SocialSecurityPctVisible := true;
        INAILContributionBaseVisible := true;
        ContributionBaseVisible := true;
        INAILNonTaxableAmountVisible := true;
        NonTaxableAmountVisible := true;
        SocialSecurityCodeVisible := true;
        INAILCodeVisible := true;
    end;

    trigger OnOpenPage()
    begin
        if GetFilter("Social Security Code") <> '' then begin
            INAILCodeVisible := false;
            SocialSecurityCodeVisible := true;
            NonTaxableAmountVisible := true;
            INAILNonTaxableAmountVisible := false;
            ContributionBaseVisible := true;
            INAILContributionBaseVisible := false;
            SocialSecurityPctVisible := true;
            INAILPerMilVisible := false;
            INAILTotalAmountVisible := false;
            TotalSocialSecurityAmountVisib := true;
            FreeLanceAmountPctVisible := true;
            INAILFreeLancePctVisible := false;
            INAILFreeLanceAmountVisible := false;
            FreeLanceAmountVisible := true;
            CompanyAmountVisible := true;
            INAILCompanyAmountVisible := false;
        end;

        if GetFilter("INAIL Code") <> '' then begin
            SocialSecurityCodeVisible := false;
            INAILCodeVisible := true;
            NonTaxableAmountVisible := false;
            INAILNonTaxableAmountVisible := true;
            ContributionBaseVisible := false;
            INAILContributionBaseVisible := true;
            SocialSecurityPctVisible := false;
            INAILPerMilVisible := true;
            INAILTotalAmountVisible := true;
            TotalSocialSecurityAmountVisib := false;
            FreeLanceAmountPctVisible := false;
            INAILFreeLancePctVisible := true;
            INAILFreeLanceAmountVisible := true;
            FreeLanceAmountVisible := false;
            CompanyAmountVisible := false;
            INAILCompanyAmountVisible := true;
        end;
    end;

    var
        [InDataSet]
        INAILCodeVisible: Boolean;
        [InDataSet]
        SocialSecurityCodeVisible: Boolean;
        [InDataSet]
        NonTaxableAmountVisible: Boolean;
        [InDataSet]
        INAILNonTaxableAmountVisible: Boolean;
        [InDataSet]
        ContributionBaseVisible: Boolean;
        [InDataSet]
        INAILContributionBaseVisible: Boolean;
        [InDataSet]
        SocialSecurityPctVisible: Boolean;
        [InDataSet]
        INAILPerMilVisible: Boolean;
        [InDataSet]
        INAILTotalAmountVisible: Boolean;
        [InDataSet]
        TotalSocialSecurityAmountVisib: Boolean;
        [InDataSet]
        FreeLanceAmountPctVisible: Boolean;
        [InDataSet]
        INAILFreeLancePctVisible: Boolean;
        [InDataSet]
        INAILFreeLanceAmountVisible: Boolean;
        [InDataSet]
        FreeLanceAmountVisible: Boolean;
        [InDataSet]
        CompanyAmountVisible: Boolean;
        [InDataSet]
        INAILCompanyAmountVisible: Boolean;
}

