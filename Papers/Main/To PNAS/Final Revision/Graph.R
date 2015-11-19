counts <- c(204,197,172);
se <- c(3,3,3);
condition <- factor(c("Model-based","Model-free goal","Model-free"),c("Model-based","Model-free goal","Model-free"))
my.data <- data.frame(condition,counts,se);
theme_set(theme_gray(base_size=30))

tiff("FigS1.tif",width=800,height=400)
ggplot(my.data,aes(x=condition,y=counts,fill=condition))+
  geom_bar(stat="identity")+
  geom_errorbar(aes(ymin=counts-se,ymax=counts+se),
                width=.2,position=position_dodge(.9))+
  scale_y_continuous(limits=c(150,210),oob = rescale_none)+
  xlab("")+
  theme(axis.text.x=element_blank(),axis.text.y=element_text(size=20,colour="black"),
        legend.title=element_blank(),axis.title.y=element_text(vjust=1.5),
        legend.key.height=unit(2,"line"))+
  scale_fill_manual(values=c("Blue","Red","Yellow"))+
  ylab("Mean reward")
dev.off()