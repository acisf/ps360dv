public class DistanceMatrixResponse {
    public List<String> destinationAddresses;
    public List<String> originAddresses;
    public List<Row> rows;
    public String status;
    
    public class Row {
        public List<Element> elements;
    }
    
    public class Element {
        public Distance distance;
        public Duration duration;
        public String status;
    }
    
    public class Distance {
        public String text;
        public Double value;
    }
    
    public class Duration {
        public String text;
        public Double value;
    }
    
    public static DistanceMatrixResponse fromJSON(String json) {
        return (DistanceMatrixResponse) System.JSON.deserialize(json, DistanceMatrixResponse.class);
    }
}