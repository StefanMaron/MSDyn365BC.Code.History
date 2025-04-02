// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.EServices.EDocument;

pageextension 10020 "Service Credit Memo NA" extends "Service Credit Memo"
{
    layout
    {
        addafter("Assigned User ID")
        {
            field("CFDI Purpose"; Rec."CFDI Purpose")
            {
                ApplicationArea = BasicMX;
                QuickEntry = false;
                ToolTip = 'Specifies the CFDI purpose required for reporting to the Mexican tax authorities (SAT).';
            }
            field("CFDI Relation"; Rec."CFDI Relation")
            {
                ApplicationArea = BasicMX;
                QuickEntry = false;
                ToolTip = 'Specifies the relation of the CFDI document. ';
            }
            field("CFDI Export Code"; Rec."CFDI Export Code")
            {
                ApplicationArea = BasicMX;
                ToolTip = 'Specifies a code to indicate if the document is used for exports to other countries.';
            }
        }
        addafter("Prices Including VAT")
        {
            field("Tax Liable"; Rec."Tax Liable")
            {
                ApplicationArea = SalesTax;
                ToolTip = 'Specifies that items, resources, or costs on the current credit memo line are liable for sales tax.';
            }
            field("Tax Area Code"; Rec."Tax Area Code")
            {
                ApplicationArea = SalesTax;
                ToolTip = 'Specifies the tax area that is used to calculate and post sales tax.';
            }
        }
    }
    actions
    {
        addafter("Service Document Lo&g")
        {
            action(CFDIRelationDocuments)
            {
                ApplicationArea = BasicMX;
                Caption = 'CFDI Relation Documents';
                Image = Allocations;
                RunObject = Page "CFDI Relation Documents";
                RunPageLink = "Document Table ID" = const(5900),
#pragma warning disable AL0603
                                "Document Type" = field("Document Type"),
#pragma warning restore AL0603
                                "Document No." = field("No."),
                                "Customer No." = field("Bill-to Customer No.");
                ToolTip = 'View or add CFDI relation documents for the record.';
            }
        }
#if not CLEAN26
        modify(Statistics)
        {
            trigger OnBeforeAction()
            begin
                OnBeforeCalculateSalesTaxStatistics(Rec, true);
            end;
        }
#endif
    }

#if not CLEAN26
    [Obsolete('Use events in OpenStatistics() procedure in table Service Header', '26.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateSalesTaxStatistics(var ServiceHeader: Record "Service Header"; ShowDialog: Boolean)
    begin
    end;
#endif
}
