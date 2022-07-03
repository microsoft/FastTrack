import { IPropertyPaneConfiguration } from '@microsoft/sp-property-pane';
import { BaseAdaptiveCardExtension } from '@microsoft/sp-adaptive-card-extension-base';
import { QuickView } from './quickView/QuickView';
import { ImageCardView } from './cardView/ImageCardView';
import { VisitorCounterPropertyPane } from './VisitorCounterPropertyPane';
import { Logger, LogLevel } from '@pnp/logging';
import { AppInsightsTelemetryTracker } from '../../service/analytics/AppInsightsTelemetryTracker';
import { TimeSpan } from '../../service/analytics/TimeSpan';
import AppInsightsAnalyticsService from '../../service/analytics/AppInsightsAnalyticsService';
import VivaConnectionsInsights from '../../service/analytics/VivaConnectionsInsights';

export interface IVisitorCounterAdaptiveCardExtensionProps {
  title: string;
  primaryText: string;
  imageUrl: string;
  analytics: string;
  aiKey: string;
  aiAppId: string;
  aiAppKey: string;  
}

export interface IVisitorCounterAdaptiveCardExtensionState {
  today: number;
  monthly: number;
  desktop: number;
  mobile: number;
  web: number;
  spo: number;
  showAnalytics: boolean;

}

const IMAGE_CARD_VIEW_REGISTRY_ID: string ='VisitorCounter_IMAGE_CARD_VIEW';
export const QUICK_VIEW_REGISTRY_ID: string = 'VisitorCounter_QUICK_VIEW';

export default class VisitorCounterAdaptiveCardExtension extends BaseAdaptiveCardExtension<
  IVisitorCounterAdaptiveCardExtensionProps,
  IVisitorCounterAdaptiveCardExtensionState
> {
  private _deferredPropertyPane: VisitorCounterPropertyPane | undefined;

  public onInit(): Promise<void> {
    try {
      Logger.activeLogLevel = LogLevel.Verbose;
      Logger.log({
        message: "Try to init VisitorCounterAdaptiveCardExtension with properties",
        data: { properties: this.properties },
        level: LogLevel.Verbose
      });      
      
      this.state = {
        today: 0,
        monthly: 0,
        desktop: 0,
        mobile: 0,
        web: 0,
        spo: 0,
        showAnalytics: false
       };

      if (this.properties.aiKey){
        Logger.log({
          message: "Try to init AppInsights tracker",
          data: { aiKey: this.properties.aiKey },
          level: LogLevel.Verbose
        });
        const ai = new AppInsightsTelemetryTracker(this.properties.aiKey);         
        ai.trackEvent(this.context.deviceContext); 
        try{
          Logger.subscribe(ai);   
        }
        catch {} 
      }

      // This matters only for several people, get them from properties (upn separted by columns)
      if (this.properties.analytics && this.properties.analytics.length > 0){
        const people: string = this.properties.analytics;
        let result = people.indexOf(this.context.pageContext.user.email);      
        if (result >= 0){
          if (this.properties.aiAppId && this.properties.aiAppKey){
            const appInsightsSvc = new AppInsightsAnalyticsService(this.context.httpClient, this.properties.aiAppId, this.properties.aiAppKey);
            this.getInsights(appInsightsSvc);
          }
        }
      }
      
      this.cardNavigator.register(IMAGE_CARD_VIEW_REGISTRY_ID, () => new ImageCardView());
      this.quickViewNavigator.register(QUICK_VIEW_REGISTRY_ID, () => new QuickView());

      return Promise.resolve();
    }
    catch (error) {
      Logger.write(`Error in onInit: ${error.message}`, LogLevel.Error);
    }    
  }

  protected loadPropertyPaneResources(): Promise<void> {
    Logger.log({
          message: "Begin loadPropertyPaneResources",
          level: LogLevel.Verbose
        });
    return import(
      /* webpackChunkName: 'VisitorCounter-property-pane'*/
      './VisitorCounterPropertyPane'
    )
      .then(
        (component) => {
          this._deferredPropertyPane = new component.VisitorCounterPropertyPane();
          Logger.log({
            message: "End loadPropertyPaneResources",
            level: LogLevel.Verbose
          });
        }
      );
  }

  protected getPropertyPaneConfiguration(): IPropertyPaneConfiguration {
    Logger.log({
      message: "Begin getPropertyPaneConfiguration",
      level: LogLevel.Verbose
    });
    return this._deferredPropertyPane!.getPropertyPaneConfiguration();
  }

  protected renderCard(): string | undefined {
    Logger.log({ message: 'Begin renderCard()', level: LogLevel.Verbose});
    return IMAGE_CARD_VIEW_REGISTRY_ID;
  }

  private getInsights = async (appInsightsSvc: AppInsightsAnalyticsService) => {
    const resultToday: any[] = await VivaConnectionsInsights.getTodaySessions(appInsightsSvc);
    
    const monthlyCount: any[] = await VivaConnectionsInsights.getMonthlySessions(appInsightsSvc);
    const resultMobile: any[] = await VivaConnectionsInsights.getMobileSessions(appInsightsSvc, TimeSpan['30 days']);
    const resultDesktop: any[] = await VivaConnectionsInsights.getDesktopSessions(appInsightsSvc, TimeSpan['30 days']);
    const resultWeb: any[] = await VivaConnectionsInsights.getWebSessions(appInsightsSvc, TimeSpan['30 days']);
    const resultSPO: any[] = await VivaConnectionsInsights.getSharePointSessions(appInsightsSvc, TimeSpan['30 days']);  

    Promise.all([resultToday, monthlyCount, resultDesktop, resultMobile, resultWeb, resultSPO]).then(()=>{
      Logger.log({
        message: "All counts",
        data: { thisState: this.state },
        level: LogLevel.Verbose
      });
      
      this.setState(
        {
          today: resultToday?.length === 1 ? resultToday[0] : 0,
          monthly: monthlyCount?.length === 1 ? monthlyCount[0] : 0,
          desktop: resultDesktop?.length === 1 ? resultDesktop[0] : 0,
          mobile: resultMobile?.length === 1 ? resultMobile[0] : 0,
          web: resultWeb?.length === 1 ? resultWeb[0] : 0,
          spo: resultSPO?.length === 1 ? resultSPO[0] : 0,
          showAnalytics: true
        });
        console.log(this.state);  
    });
  }
}
