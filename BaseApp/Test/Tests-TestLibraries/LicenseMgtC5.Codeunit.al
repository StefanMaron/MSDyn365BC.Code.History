codeunit 130031 "License Mgt. C5"
{

    trigger OnRun()
    begin
        ReduceDemoData();
    end;

    [Scope('OnPrem')]
    procedure ReduceDemoData()
    var
        BOMComponent: Record "BOM Component";
        SalesShipmentHeader: Record "Sales Shipment Header";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        AccSchedKPIWebSrvSetup: Record "Acc. Sched. KPI Web Srv. Setup";
        AccSchedKPIWebSrvLine: Record "Acc. Sched. KPI Web Srv. Line";
        BusinessUnit: Record "Business Unit";
        OrderAddress: Record "Order Address";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        CheckLedgerEntry: Record "Check Ledger Entry";
        TaxArea: Record "Tax Area";
        TaxAreaLine: Record "Tax Area Line";
        TaxJurisdiction: Record "Tax Jurisdiction";
        TaxGroup: Record "Tax Group";
        TaxDetail: Record "Tax Detail";
        DimensionCombination: Record "Dimension Combination";
        DimensionValueCombination: Record "Dimension Value Combination";
        DefaultDimensionPriority: Record "Default Dimension Priority";
        AnalysisView: Record "Analysis View";
        AnalysisViewFilter: Record "Analysis View Filter";
        AnalysisViewEntry: Record "Analysis View Entry";
        AnalysisViewBudgetEntry: Record "Analysis View Budget Entry";
        SalesPrepaymentPct: Record "Sales Prepayment %";
        PurchasePrepaymentPct: Record "Purchase Prepayment %";
        CertificateOfSupply: Record "Certificate of Supply";
        AssemblyCommentLine: Record "Assembly Comment Line";
        PostedAssemblyHeader: Record "Posted Assembly Header";
        PostedAssemblyLine: Record "Posted Assembly Line";
        PostedAssembleToOrderLink: Record "Posted Assemble-to-Order Link";
        AdditionalFeeSetup: Record "Additional Fee Setup";
        ReminderTermsTranslation: Record "Reminder Terms Translation";
        DeferralHeader: Record "Deferral Header";
        DeferralLine: Record "Deferral Line";
        PostedDeferralHeader: Record "Posted Deferral Header";
        PostedDeferralLine: Record "Posted Deferral Line";
        Contact: Record Contact;
        ContactAltAddress: Record "Contact Alt. Address";
        ContactAltAddrDateRange: Record "Contact Alt. Addr. Date Range";
        BusinessRelation: Record "Business Relation";
        MailingGroup: Record "Mailing Group";
        ContactMailingGroup: Record "Contact Mailing Group";
        IndustryGroup: Record "Industry Group";
        ContactIndustryGroup: Record "Contact Industry Group";
        WebSource: Record "Web Source";
        ContactWebSource: Record "Contact Web Source";
        RlshpMgtCommentLine: Record "Rlshp. Mgt. Comment Line";
        Attachment: Record Attachment;
        InteractionGroup: Record "Interaction Group";
        InteractionTemplate: Record "Interaction Template";
        InteractionLogEntry: Record "Interaction Log Entry";
        JobResponsibility: Record "Job Responsibility";
        ContactJobResponsibility: Record "Contact Job Responsibility";
        Salutation: Record Salutation;
        SalutationFormula: Record "Salutation Formula";
        OrganizationalLevel: Record "Organizational Level";
        Campaign: Record Campaign;
        CampaignEntry: Record "Campaign Entry";
        CampaignStatus: Record "Campaign Status";
        LoggedSegment: Record "Logged Segment";
        SegmentHeader: Record "Segment Header";
        SegmentLine: Record "Segment Line";
        SegmentHistory: Record "Segment History";
        ToDo: Record "To-do";
        Activity: Record Activity;
        ActivityStep: Record "Activity Step";
        Team: Record Team;
        TeamSalesperson: Record "Team Salesperson";
        ContactDuplicate: Record "Contact Duplicate";
        ContDuplicateSearchString: Record "Cont. Duplicate Search String";
        ProfileQuestionnaireHeader: Record "Profile Questionnaire Header";
        ProfileQuestionnaireLine: Record "Profile Questionnaire Line";
        ContactProfileAnswer: Record "Contact Profile Answer";
        SalesCycle: Record "Sales Cycle";
        SalesCycleStage: Record "Sales Cycle Stage";
        Opportunity: Record Opportunity;
        OpportunityEntry: Record "Opportunity Entry";
        CloseOpportunityCode: Record "Close Opportunity Code";
        DuplicateSearchStringSetup: Record "Duplicate Search String Setup";
        SegmentWizardFilter: Record "Segment Wizard Filter";
        SegmentCriteriaLine: Record "Segment Criteria Line";
        SavedSegmentCriteria: Record "Saved Segment Criteria";
        SavedSegmentCriteriaLine: Record "Saved Segment Criteria Line";
        CommunicationMethod: Record "Communication Method";
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
        SegmentInteractionLanguage: Record "Segment Interaction Language";
        Rating: Record Rating;
        InterLogEntryCommentLine: Record "Inter. Log Entry Comment Line";
        ToDoInteractionLanguage: Record "To-do Interaction Language";
        Attendee: Record Attendee;
        CRMSynchJobStatusCue: Record "CRM Synch. Job Status Cue";
        ProductionOrder: Record "Production Order";
        UnplannedDemand: Record "Unplanned Demand";
        MaintenanceRegistration: Record "Maintenance Registration";
        Maintenance: Record Maintenance;
        Insurance: Record Insurance;
        InsCoverageLedgerEntry: Record "Ins. Coverage Ledger Entry";
        InsuranceType: Record "Insurance Type";
        InsuranceRegister: Record "Insurance Register";
        StockkeepingUnit: Record "Stockkeeping Unit";
        StockkeepingUnitCommentLine: Record "Stockkeeping Unit Comment Line";
        ItemSubstitution: Record "Item Substitution";
        SubstitutionCondition: Record "Substitution Condition";
        NonstockItem: Record "Nonstock Item";
        TransferHeader: Record "Transfer Header";
        TransferRoute: Record "Transfer Route";
        ShippingAgentServices: Record "Shipping Agent Services";
        ItemCharge: Record "Item Charge";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        SerialNoInformation: Record "Serial No. Information";
        LotNoInformation: Record "Lot No. Information";
        ItemTrackingComment: Record "Item Tracking Comment";
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
        ReturnReason: Record "Return Reason";
        ReturnShipmentHeader: Record "Return Shipment Header";
        ReturnReceiptHeader: Record "Return Receipt Header";
        ItemBudgetName: Record "Item Budget Name";
        ItemBudgetEntry: Record "Item Budget Entry";
        ItemAnalysisViewFilter: Record "Item Analysis View Filter";
        ItemAnalysisViewEntry: Record "Item Analysis View Entry";
        ItemAnalysisViewBudgEntry: Record "Item Analysis View Budg. Entry";
        AnalysisSelectedDimension: Record "Analysis Selected Dimension";
        WarehouseEmployee: Record "Warehouse Employee";
        BinContent: Record "Bin Content";
        BinType: Record "Bin Type";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WarehouseEntry: Record "Warehouse Entry";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        InternalMovementHeader: Record "Internal Movement Header";
        InternalMovementLine: Record "Internal Movement Line";
        Bin: Record Bin;
        CustomReportSelection: Record "Custom Report Selection";
        ManufacturingCommentLine: Record "Manufacturing Comment Line";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionBOMCommentLine: Record "Production BOM Comment Line";
        LicenseManagementStarter: Codeunit "License Management Starter";
    begin
        LicenseManagementStarter.ReduceDemoData();
        BOMComponent.DeleteAll();
        SalesShipmentHeader.DeleteAll();
        PurchRcptHeader.DeleteAll();
        PurchRcptLine.DeleteAll();
        IncomingDocumentAttachment.DeleteAll();
        AccSchedKPIWebSrvSetup.DeleteAll();
        AccSchedKPIWebSrvLine.DeleteAll();
        BusinessUnit.DeleteAll();
        OrderAddress.DeleteAll();
        ReqWkshTemplate.DeleteAll();
        RequisitionWkshName.DeleteAll();
        CheckLedgerEntry.DeleteAll();
        TaxArea.DeleteAll();
        TaxAreaLine.DeleteAll();
        TaxJurisdiction.DeleteAll();
        TaxGroup.DeleteAll();
        TaxDetail.DeleteAll();
        DimensionCombination.DeleteAll();
        DimensionValueCombination.DeleteAll();
        DefaultDimensionPriority.DeleteAll();
        AnalysisView.DeleteAll();
        AnalysisViewFilter.DeleteAll();
        AnalysisViewEntry.DeleteAll();
        AnalysisViewBudgetEntry.DeleteAll();
        SalesPrepaymentPct.DeleteAll();
        PurchasePrepaymentPct.DeleteAll();
        CertificateOfSupply.DeleteAll();
        AssemblyCommentLine.DeleteAll();
        PostedAssemblyHeader.DeleteAll();
        PostedAssemblyLine.DeleteAll();
        PostedAssembleToOrderLink.DeleteAll();
        AdditionalFeeSetup.DeleteAll();
        ReminderTermsTranslation.DeleteAll();
        DeferralHeader.DeleteAll();
        DeferralLine.DeleteAll();
        PostedDeferralHeader.DeleteAll();
        PostedDeferralLine.DeleteAll();
        Contact.DeleteAll();
        ContactAltAddress.DeleteAll();
        ContactAltAddrDateRange.DeleteAll();
        BusinessRelation.DeleteAll();
        MailingGroup.DeleteAll();
        ContactMailingGroup.DeleteAll();
        IndustryGroup.DeleteAll();
        ContactIndustryGroup.DeleteAll();
        WebSource.DeleteAll();
        ContactWebSource.DeleteAll();
        RlshpMgtCommentLine.DeleteAll();
        Attachment.DeleteAll();
        InteractionGroup.DeleteAll();
        InteractionTemplate.DeleteAll();
        InteractionLogEntry.DeleteAll();
        JobResponsibility.DeleteAll();
        ContactJobResponsibility.DeleteAll();
        Salutation.DeleteAll();
        SalutationFormula.DeleteAll();
        OrganizationalLevel.DeleteAll();
        Campaign.DeleteAll();
        CampaignEntry.DeleteAll();
        CampaignStatus.DeleteAll();
        LoggedSegment.DeleteAll();
        SegmentHeader.DeleteAll();
        SegmentLine.DeleteAll();
        SegmentHistory.DeleteAll();
        ToDo.DeleteAll();
        Activity.DeleteAll();
        ActivityStep.DeleteAll();
        Team.DeleteAll();
        TeamSalesperson.DeleteAll();
        ContactDuplicate.DeleteAll();
        ContDuplicateSearchString.DeleteAll();
        ProfileQuestionnaireHeader.DeleteAll();
        ProfileQuestionnaireLine.DeleteAll();
        ContactProfileAnswer.DeleteAll();
        SalesCycle.DeleteAll();
        SalesCycleStage.DeleteAll();
        Opportunity.DeleteAll();
        OpportunityEntry.DeleteAll();
        CloseOpportunityCode.DeleteAll();
        DuplicateSearchStringSetup.DeleteAll();
        SegmentWizardFilter.DeleteAll();
        SegmentCriteriaLine.DeleteAll();
        SavedSegmentCriteria.DeleteAll();
        SavedSegmentCriteriaLine.DeleteAll();
        CommunicationMethod.DeleteAll();
        InteractionTmplLanguage.DeleteAll();
        SegmentInteractionLanguage.DeleteAll();
        Rating.DeleteAll();
        InterLogEntryCommentLine.DeleteAll();
        ToDoInteractionLanguage.DeleteAll();
        Attendee.DeleteAll();
        CRMSynchJobStatusCue.DeleteAll();
        ProductionOrder.DeleteAll();
        UnplannedDemand.DeleteAll();
        MaintenanceRegistration.DeleteAll();
        Maintenance.DeleteAll();
        Insurance.DeleteAll();
        InsCoverageLedgerEntry.DeleteAll();
        InsuranceType.DeleteAll();
        InsuranceRegister.DeleteAll();
        StockkeepingUnit.DeleteAll();
        StockkeepingUnitCommentLine.DeleteAll();
        ItemSubstitution.DeleteAll();
        SubstitutionCondition.DeleteAll();
        NonstockItem.DeleteAll();
        TransferHeader.DeleteAll();
        TransferRoute.DeleteAll();
        ShippingAgentServices.DeleteAll();
        ItemCharge.DeleteAll();
        ItemChargeAssignmentPurch.DeleteAll();
        ItemChargeAssignmentSales.DeleteAll();
        SerialNoInformation.DeleteAll();
        LotNoInformation.DeleteAll();
        ItemTrackingComment.DeleteAll();
        WhseItemTrackingLine.DeleteAll();
        ReturnReason.DeleteAll();
        ReturnShipmentHeader.DeleteAll();
        ReturnReceiptHeader.DeleteAll();
        ItemBudgetName.DeleteAll();
        ItemBudgetEntry.DeleteAll();
        ItemAnalysisViewFilter.DeleteAll();
        ItemAnalysisViewEntry.DeleteAll();
        ItemAnalysisViewBudgEntry.DeleteAll();
        AnalysisSelectedDimension.DeleteAll();
        WarehouseEmployee.DeleteAll();
        BinContent.DeleteAll();
        BinType.DeleteAll();
        WarehouseJournalTemplate.DeleteAll();
        WarehouseJournalBatch.DeleteAll();
        WarehouseJournalLine.DeleteAll();
        WarehouseEntry.DeleteAll();
        WhseWorksheetLine.DeleteAll();
        WhseWorksheetName.DeleteAll();
        WhseWorksheetTemplate.DeleteAll();
        InternalMovementHeader.DeleteAll();
        InternalMovementLine.DeleteAll();
        Bin.DeleteAll();
        CustomReportSelection.DeleteAll();
        ManufacturingCommentLine.DeleteAll();
        ProductionBOMHeader.DeleteAll();
        ProductionBOMLine.DeleteAll();
        ProductionBOMCommentLine.DeleteAll();
    end;
}

