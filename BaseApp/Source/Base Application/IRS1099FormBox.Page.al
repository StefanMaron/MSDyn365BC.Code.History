page 10015 "IRS 1099 Form-Box"
{
    ApplicationArea = Basic, Suite;
    Caption = '1099 Form Boxes';
    PageType = List;
    SourceTable = "IRS 1099 Form-Box";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = BasicUS;
                    ToolTip = 'Specifies the 1099 form and the 1099 box.';
                }
                field(Description; Description)
                {
                    ApplicationArea = BasicUS;
                    ToolTip = 'Specifies a description of the 1099 code.';
                }
                field("Minimum Reportable"; "Minimum Reportable")
                {
                    ApplicationArea = BasicUS;
                    ToolTip = 'Specifies the minimum value for this box that must be reported to the IRS on a 1099 form.';
                }
                field("Adjustment Exists"; "Adjustment Exists")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if adjustment exists for this 1099 form and the 1099 box.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Update Form Boxes")
            {
                ApplicationArea = BasicUS;
                Caption = 'Update Form Boxes';
                Image = "1099Form";
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Update the form boxes in the report to map to changed codes in the related table.';

                trigger OnAction()
                var
                    IRS1099Management: Codeunit "IRS 1099 Management";
                begin
                    IRS1099Management.UpgradeFormBoxes;
                end;
            }
            action("Vendor 1099 Magnetic Media")
            {
                ApplicationArea = BasicUS;
                Caption = 'Vendor 1099 Magnetic Media';
                Image = Export1099;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Report "Vendor 1099 Magnetic Media";
                ToolTip = 'View the 1099 forms that can be exported. The form information exported by this report is the same as the reports that print 1099 forms. These reports include Vendor 1099 Div, Vendor 1099 Int, and Vendor 1099 Misc.';
            }
            action(Adjustments)
            {
                ApplicationArea = Basic, Suite;
                Image = AdjustEntries;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "IRS 1099 Adjustments";
                RunPageLink = "IRS 1099 Code" = FIELD(Code);
                RunPageView = SORTING("Vendor No.", "IRS 1099 Code", Year);
                ToolTip = 'Specifies the adjusted amount per vendor and year.';
            }
        }
        area(reporting)
        {
            action("Vendor 1099 Div")
            {
                ApplicationArea = BasicUS;
                Caption = 'Vendor 1099 Div';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "Vendor 1099 Div";
                ToolTip = 'View the federal form 1099-DIV for dividends and distribution.';
            }
            action("Vendor 1099 Int")
            {
                ApplicationArea = BasicUS;
                Caption = 'Vendor 1099 Int';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "Vendor 1099 Int";
                ToolTip = 'View the federal form 1099-INT for interest income.';
            }
            action("Vendor 1099 Misc")
            {
                ApplicationArea = BasicUS;
                Caption = 'Vendor 1099 Misc';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                ToolTip = 'View the federal form 1099-MISC for miscellaneous income.';

                trigger OnAction()
                var
                    IRS1099Management: Codeunit "IRS 1099 Management";
                begin
                    IRS1099Management.Run1099MiscReport();
                end;
            }
            action(RunVendor1099NecReport)
            {
                ApplicationArea = BasicUS;
                Caption = 'Vendor 1099 Nec';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                ToolTip = 'View the federal form 1099-NEC for nonemployee compensation.';

                trigger OnAction()
                var
                    IRS1099Management: Codeunit "IRS 1099 Management";
                begin
                    IRS1099Management.Run1099NecReport();
                end;
            }
            action("Vendor 1099 Information")
            {
                ApplicationArea = BasicUS;
                Caption = 'Vendor 1099 Information';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "Vendor 1099 Information";
                ToolTip = 'View the vendors'' 1099 information. The report includes all 1099 information for the vendors that have been set up using the IRS 1099 Form-Box table. This includes only amounts that have been paid. It does not include amounts billed but not yet paid. You must enter a date filter before you can print this report.';
            }
        }
    }

    trigger OnOpenPage()
    var
        IRS1099Management: Codeunit "IRS 1099 Management";
    begin
        IRS1099Management.ShowUpgradeFormBoxesNotificationIfUpgradeNeeded;
    end;
}

