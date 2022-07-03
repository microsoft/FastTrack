import { HttpClient, IHttpClientOptions, HttpClientResponse } from "@microsoft/sp-http";
import { Logger, LogLevel } from "@pnp/logging";
import { TimeSpan } from "./TimeSpan";


export default class AppInsightsAnalyticsService {
    private appInsightsEndpoint: string = 'https://api.applicationinsights.io/v1/apps';
    private httpClient: HttpClient;
    private httpClientOptions: IHttpClientOptions;
    private requestHeaders: Headers = new Headers(); 
    
    public constructor(httpClient: HttpClient, appId: string, appKey: string){
        this.httpClient = httpClient;
        this.appInsightsEndpoint += `/${appId}`;
        
        this.requestHeaders.append('Content-type', 'application/json; charset=utf-8');
        this.requestHeaders.append('x-api-key', appKey);
        this.httpClientOptions = { headers: this.requestHeaders };
    }
    
    private executeQuery = async (queryUrl: string): Promise<any> => {
        let response: HttpClientResponse = await this.httpClient.get(queryUrl, HttpClient.configurations.v1, this.httpClientOptions);
        return await response.json();
    }

    public getQueryResultAsync = async (query: string, timespan?: TimeSpan): Promise<any[]>=>{
        Logger.log({ message: timespan, level: LogLevel.Verbose});
        let queryUrl: string = timespan ? `timespan=${timespan}&query=${encodeURIComponent(query)}` : `query=${encodeURIComponent(query)}`;
        const url: string = this.appInsightsEndpoint + `/query?${queryUrl}`; 

        let resp: any = await this.executeQuery(url);
        let result: any[] = [];
        if (resp.tables.length > 0){
            result = resp.tables[0].rows;
        }
        return result;
    }


    public getQueryResult = (query: string, timespan?: TimeSpan) =>{
        Logger.log({ message: timespan, level: LogLevel.Verbose});
        let queryUrl: string = timespan ? `timespan=${timespan}&query=${encodeURIComponent(query)}` : `query=${encodeURIComponent(query)}`;
        let url: string = this.appInsightsEndpoint + `/query?${queryUrl}`; 

        this.executeQuery(url).then(resp => {
            let result: any[] = [];
            if (resp.tables.length > 0){
                result = resp.tables[0].rows;
            }
            return result;
        });        
    }
}