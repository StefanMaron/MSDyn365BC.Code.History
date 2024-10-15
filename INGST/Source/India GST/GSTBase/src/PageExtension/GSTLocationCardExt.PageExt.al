pageextension 18009 "GST Location Card Ext" extends "Location Card"
{
    layout
    {
        addlast("Tax Information")
        {
            field("Subcontracting Location"; "Subcontracting Location")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies if location is subcontractor''s location.';
            }
            field("Subcontractor No."; "Subcontractor No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the subcontracting vendor code related to subcontracting location.';

            }
            field("Input Service Distributor"; "Input Service Distributor")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies whether the location is an input service distributor.';
            }
            field("Export or Deemed Export"; "Export or Deemed Export")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies whether the location is related to export or deemed export.';
            }
            field("GST Registration No."; "GST Registration No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the goods and services tax registration number of the location.';
            }
            field("GST Input Service Distributor"; "GST Input Service Distributor")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies whether the location is a GST input service distributor.';
            }
            field("Location ARN No."; "Location ARN No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the ARN number in case goods and service tax registration number is not available with the company.';
            }
            field("Bonded warehouse"; "Bonded warehouse")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies if location is defined as a bonded warehouse.';
            }
            field("Trading Location"; "Trading Location")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Spacifies location use as a Trading Location';
            }
            field(Composition; Composition)
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Spacifies location use as a Composition';

            }
            field("Composition Type"; "Composition Type")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Spacifies the type of Composition';
            }
        }
    }
}
