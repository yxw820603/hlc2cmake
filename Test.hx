import h2d.Text;
import h2d.Flow;

class Test extends hxd.App {
    var text:Text;
    var flow:Flow;

    override function init() {
        Sys.println("Test app initialized!");  // 添加这行调试输出
        
        // 创建一个流式布局容器
        flow = new Flow(s2d);
        flow.horizontalAlign = Middle;
        flow.verticalAlign = Middle;
        flow.maxWidth = s2d.width;
        flow.maxHeight = s2d.height;

        // 创建文本
        var font = hxd.res.DefaultFont.get();
        text = new Text(font, flow);
        text.text = "Hello from Heaps Engine!";
        text.scale(4);  // 放大文本
        text.textColor = 0xFFFFFF;  // 白色文本
    }

    override function update(dt:Float) {
        // 保持文本居中
        flow.maxWidth = s2d.width;
        flow.maxHeight = s2d.height;
    }

    static function main() {
        new Test();
    }
}
